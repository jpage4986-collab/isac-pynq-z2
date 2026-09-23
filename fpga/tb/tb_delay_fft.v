`timescale 1ns/1ps
module tb_delay_fft;
    reg clk = 0, rst = 1;
    reg in_valid = 0, in_last = 0;
    reg signed [15:0] in_i = 0;
    wire in_ready;
    wire ifft_valid, ifft_ready, ifft_last;
    wire signed [15:0] ifft_i, ifft_q;
    wire cp_valid, cp_ready, cp_last;
    wire signed [15:0] cp_i, cp_q;
    wire channel_valid, channel_ready, channel_last;
    wire signed [15:0] channel_i, channel_q;
    wire rx_valid, rx_ready, rx_last;
    wire signed [15:0] rx_i, rx_q;
    wire fft_valid, fft_last;
    wire signed [15:0] fft_i, fft_q;
    integer k, out_count = 0;

    always #4 clk = ~clk;
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
    digital_delay_channel_axis #(.DELAY(5)) u_channel (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(cp_valid), .s_axis_tready(cp_ready),
        .s_axis_tlast(cp_last), .s_axis_i(cp_i), .s_axis_q(cp_q),
        .m_axis_tready(channel_ready), .m_axis_tvalid(channel_valid),
        .m_axis_tlast(channel_last), .m_axis_i(channel_i), .m_axis_q(channel_q)
    );
    cp_remove_axis u_cp_remove (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(channel_valid), .s_axis_tready(channel_ready),
        .s_axis_i(channel_i), .s_axis_q(channel_q),
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
            if (out_count == 1) begin
                if (fft_i < 16'sd190 || fft_i > 16'sd260 ||
                    fft_q < -16'sd155 || fft_q > -16'sd85)
                    $fatal(1, "delayed bin 1 got (%0d,%0d), expected about (226,-121)", fft_i, fft_q);
            end else if (fft_i < -35 || fft_i > 35 || fft_q < -35 || fft_q > 35) begin
                $fatal(1, "unexpected energy at bin %0d: (%0d,%0d)", out_count, fft_i, fft_q);
            end
            if (fft_last !== (out_count == 63))
                $fatal(1, "FFT TLAST mismatch at bin %0d", out_count);
            out_count = out_count + 1;
            if (out_count == 64) begin
                $display("PASS delay FFT: bin 1 phase matches a 5-sample target delay");
                $finish;
            end
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        @(negedge clk); rst = 0;
        for (k = 0; k < 64; k = k + 1) begin
            @(negedge clk);
            in_valid = 1;
            in_last = (k == 63);
            in_i = (k == 1) ? 16'sd16384 : 16'sd0;
            @(posedge clk);
            while (!in_ready) @(posedge clk);
        end
        @(negedge clk); in_valid = 0; in_last = 0;
    end

    initial begin
        #100000;
        $fatal(1, "delay FFT test timed out");
    end
endmodule
