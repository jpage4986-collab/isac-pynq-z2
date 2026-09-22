`timescale 1ns/1ps
module tb_fft64_roundtrip;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg in_valid = 1'b0;
    reg in_last = 1'b0;
    reg signed [15:0] in_i = 0;
    wire in_ready;
    wire ifft_valid, ifft_ready, ifft_last;
    wire signed [15:0] ifft_i, ifft_q;
    wire cp_valid, cp_ready, cp_last;
    wire signed [15:0] cp_i, cp_q;
    wire rx_valid, rx_ready, rx_last;
    wire signed [15:0] rx_i, rx_q;
    wire fft_valid, fft_last;
    wire signed [15:0] fft_i, fft_q;
    integer k, out_count = 0, expected;
    reg roundtrip_done = 1'b0;
    wire led0, led1, led2, led3;
    wire fault_sticky;
    wire [31:0] fault_bits, fault_errors;
    wire inject_one_error = u_board_top.fft_valid &&
                            u_board_top.u_checker.data_frame &&
                            (u_board_top.u_checker.data_frame_count == 0) &&
                            (u_board_top.u_checker.bin_index == 6'd1);
    wire signed [15:0] fault_i = inject_one_error ? -u_board_top.fft_i : u_board_top.fft_i;

    always #4 clk = ~clk;

    // Exercise the exact board top and its result checker as well.
    isac_top u_board_top (
        .clk(clk), .btn0(rst),
        .led0(led0), .led1(led1), .led2(led2), .led3(led3)
    );
    ofdm_frame_checker u_fault_checker (
        .clk(clk), .rst(rst),
        .s_valid(u_board_top.fft_valid), .s_last(u_board_top.fft_last),
        .s_i(fault_i), .s_q(u_board_top.fft_q),
        .frame_seen(), .data_frame_seen(), .last_frame_ok(),
        .sticky_error(fault_sticky), .frame_count(), .data_frame_count(),
        .bit_count(fault_bits), .bit_errors(fault_errors)
    );

    fft64_axis_wrapper #(.INVERSE(1'b1)) u_ifft (
        .clk(clk), .rst(rst), .s_valid(in_valid), .s_ready(in_ready),
        .s_last(in_last), .s_i(in_i), .s_q(16'sd0),
        .m_valid(ifft_valid), .m_ready(ifft_ready), .m_last(ifft_last),
        .m_i(ifft_i), .m_q(ifft_q)
    );
    cp_insert_axis u_cp_insert (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(ifft_valid), .s_axis_tready(ifft_ready),
        .s_axis_i(ifft_i), .s_axis_q(ifft_q),
        .m_axis_tready(cp_ready), .m_axis_tvalid(cp_valid),
        .m_axis_tlast(cp_last), .m_axis_i(cp_i), .m_axis_q(cp_q)
    );
    cp_remove_axis u_cp_remove (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(cp_valid), .s_axis_tready(cp_ready),
        .s_axis_i(cp_i), .s_axis_q(cp_q),
        .m_axis_tready(rx_ready), .m_axis_tvalid(rx_valid),
        .m_axis_tlast(rx_last), .m_axis_i(rx_i), .m_axis_q(rx_q)
    );
    fft64_axis_wrapper u_fft (
        .clk(clk), .rst(rst), .s_valid(rx_valid), .s_ready(rx_ready),
        .s_last(rx_last), .s_i(rx_i), .s_q(rx_q),
        .m_valid(fft_valid), .m_ready(1'b1), .m_last(fft_last),
        .m_i(fft_i), .m_q(fft_q)
    );

    always @(posedge clk) begin
        if (fft_valid) begin
            expected = (out_count == 1 || out_count == 63) ? 256 : 0;
            if (fft_i < expected - 32 || fft_i > expected + 32 ||
                fft_q < -32 || fft_q > 32)
                $fatal(1, "FFT roundtrip bin %0d got (%0d,%0d), expected about (%0d,0)",
                       out_count, fft_i, fft_q, expected);
            if (fft_last !== (out_count == 63))
                $fatal(1, "FFT output TLAST mismatch at bin %0d", out_count);
            out_count = out_count + 1;
            if (out_count == 64) roundtrip_done = 1'b1;
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        @(negedge clk); rst = 1'b0;
        for (k = 0; k < 64; k = k + 1) begin
            @(negedge clk);
            in_valid = 1'b1;
            in_last = (k == 63);
            in_i = (k == 1 || k == 63) ? 16'sd16384 : 16'sd0;
            @(posedge clk);
            while (!in_ready) @(posedge clk);
        end
        @(negedge clk); in_valid = 1'b0; in_last = 1'b0;
    end

    initial begin
        wait (roundtrip_done && u_board_top.data_frame_count >= 4);
        @(negedge clk);
        if (!led1 || led3)
            $fatal(1, "Board checker failed: pass=%b frame_seen=%b error=%b", led1, led2, led3);
        if (u_board_top.bit_count !== 32'd384 || u_board_top.bit_errors !== 32'd0)
            $fatal(1, "QPSK BER mismatch: bits=%0d errors=%0d", u_board_top.bit_count, u_board_top.bit_errors);
        if (!fault_sticky || fault_bits !== 32'd384 || fault_errors !== 32'd1)
            $fatal(1, "Injected error was not counted once: bits=%0d errors=%0d sticky=%b",
                   fault_bits, fault_errors, fault_sticky);
        $display("PASS QPSK OFDM: 4 data frames, %0d bits, %0d errors; primitive FFT/CP roundtrip passed",
                 u_board_top.bit_count, u_board_top.bit_errors);
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "FFT roundtrip timed out");
    end
endmodule
