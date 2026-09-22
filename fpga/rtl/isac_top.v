`timescale 1ns/1ps

// Deterministic PL-only OFDM smoke test. No ADC, DAC, radio or PS is attached.
module isac_top (
    input  wire clk,
    input  wire btn0,
    output wire led0,
    output wire led1,
    output wire led2,
    output wire led3
);
    // PYNQ-Z2 BTN0 is high only while pressed.
    wire rst = btn0;
    reg [26:0] heartbeat;
    reg [6:0] tx_index;
    reg [6:0] rx_index;
    reg frame_seen;
    reg frame_ok;
    reg frame_error;
    reg sticky_error;

    wire signed [15:0] freq_i = ((tx_index == 7'd1) || (tx_index == 7'd63)) ? 16'sd16384 : 16'sd0;
    wire signed [15:0] freq_q = 16'sd0;
    wire tx_last = (tx_index == 7'd63);
    wire ifft_s_ready, ifft_m_valid, ifft_m_last;
    wire signed [15:0] ifft_m_i, ifft_m_q;
    wire cp_s_ready, cp_m_valid, cp_m_last;
    wire signed [15:0] cp_m_i, cp_m_q;
    wire rx_s_ready, rx_m_valid, rx_m_last;
    wire signed [15:0] rx_m_i, rx_m_q;
    wire fft_s_ready, fft_m_valid, fft_m_last;
    wire signed [15:0] fft_m_i, fft_m_q;

    fft64_axis_wrapper #(.INVERSE(1'b1)) u_ifft64_tx (
        .clk(clk), .rst(rst),
        .s_valid(1'b1), .s_ready(ifft_s_ready), .s_last(tx_last),
        .s_i(freq_i), .s_q(freq_q),
        .m_valid(ifft_m_valid), .m_ready(cp_s_ready), .m_last(ifft_m_last),
        .m_i(ifft_m_i), .m_q(ifft_m_q)
    );
    cp_insert_axis u_cp_insert (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(ifft_m_valid), .s_axis_tready(cp_s_ready),
        .s_axis_i(ifft_m_i), .s_axis_q(ifft_m_q),
        .m_axis_tready(rx_s_ready), .m_axis_tvalid(cp_m_valid),
        .m_axis_tlast(cp_m_last), .m_axis_i(cp_m_i), .m_axis_q(cp_m_q)
    );
    cp_remove_axis u_cp_remove (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(cp_m_valid), .s_axis_tready(rx_s_ready),
        .s_axis_i(cp_m_i), .s_axis_q(cp_m_q),
        .m_axis_tready(fft_s_ready), .m_axis_tvalid(rx_m_valid),
        .m_axis_tlast(rx_m_last), .m_axis_i(rx_m_i), .m_axis_q(rx_m_q)
    );
    fft64_axis_wrapper u_fft64_rx (
        .clk(clk), .rst(rst),
        .s_valid(rx_m_valid), .s_ready(fft_s_ready), .s_last(rx_m_last),
        .s_i(rx_m_i), .s_q(rx_m_q),
        .m_valid(fft_m_valid), .m_ready(1'b1), .m_last(fft_m_last),
        .m_i(fft_m_i), .m_q(fft_m_q)
    );

    wire signed [16:0] expected_i = ((rx_index == 7'd1) || (rx_index == 7'd63)) ? 17'sd256 : 17'sd0;
    wire signed [16:0] actual_i = {fft_m_i[15], fft_m_i};
    wire signed [16:0] actual_q = {fft_m_q[15], fft_m_q};
    wire sample_error = (actual_i < expected_i - 17'sd32) ||
                        (actual_i > expected_i + 17'sd32) ||
                        (actual_q < -17'sd32) || (actual_q > 17'sd32) ||
                        (fft_m_last != (rx_index == 7'd63));

    always @(posedge clk) begin
        heartbeat <= heartbeat + 1'b1;
        if (rst) begin
            tx_index <= 7'd0;
            rx_index <= 7'd0;
            frame_seen <= 1'b0;
            frame_ok <= 1'b0;
            frame_error <= 1'b0;
            sticky_error <= 1'b0;
        end else begin
            if (ifft_s_ready)
                tx_index <= tx_last ? 7'd0 : tx_index + 1'b1;
            if (fft_m_valid) begin
                if (sample_error) begin
                    frame_error <= 1'b1;
                    sticky_error <= 1'b1;
                end
                if (fft_m_last) begin
                    frame_seen <= 1'b1;
                    frame_ok <= !frame_error && !sample_error;
                    frame_error <= 1'b0;
                    rx_index <= 7'd0;
                end else begin
                    rx_index <= rx_index + 1'b1;
                end
            end
        end
    end

    assign led0 = heartbeat[26]; // clock alive
    assign led1 = frame_seen && frame_ok; // most recent full frame passed
    assign led2 = frame_seen; // at least one output frame completed
    assign led3 = sticky_error; // any output mismatch since BTN0 reset
endmodule
