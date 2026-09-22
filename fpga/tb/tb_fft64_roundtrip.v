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
    integer board_frames = 0;
    reg roundtrip_done = 1'b0;
    wire led0, led1, led2, led3;

    always #4 clk = ~clk;

    always @(posedge clk)
        if (!rst && u_board_top.fft_m_valid && u_board_top.fft_m_last)
            board_frames = board_frames + 1;

    // Exercise the exact board top and its result checker as well.
    isac_top u_board_top (
        .clk(clk), .btn0(rst),
        .led0(led0), .led1(led1), .led2(led2), .led3(led3)
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
        wait (roundtrip_done && board_frames >= 4);
        if (!led1 || led3)
            $fatal(1, "Board checker failed: pass=%b frame_seen=%b error=%b", led1, led2, led3);
        $display("PASS full OFDM loopback and board checker: IFFT, CP insert/remove, FFT, 64 bins, TLAST, %0d board frames", board_frames);
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "FFT roundtrip timed out");
    end
endmodule
