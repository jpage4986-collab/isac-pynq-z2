`timescale 1ns/1ps

// Board-level 5-sample digital-target sensing demonstration.
// LED0 blinks, LED1 means a range profile was completed, LED2 means the
// strongest range bin is the expected bin 5, and LED3 flags another result.
module range_demo_top (
    input  wire clk,
    input  wire btn0,
    output wire led0,
    output wire led1,
    output wire led2,
    output wire led3
);
    wire rst = btn0;
    reg [26:0] heartbeat;
    wire tx_valid, tx_ready, tx_last;
    wire signed [15:0] tx_i, tx_q;
    wire ifft_valid, ifft_ready, ifft_last;
    wire signed [15:0] ifft_i, ifft_q;
    wire cp_valid, cp_ready, cp_last;
    wire signed [15:0] cp_i, cp_q;
    wire delayed_valid, delayed_ready, delayed_last;
    wire signed [15:0] delayed_i, delayed_q;
    wire rx_valid, rx_ready, rx_last;
    wire signed [15:0] rx_i, rx_q;
    wire fft_valid, fft_ready, fft_last;
    wire signed [15:0] fft_i, fft_q;
    wire h_valid, h_ready, h_last;
    wire signed [15:0] h_i, h_q;
    wire range_valid, range_last;
    wire signed [15:0] range_i, range_q;
    (* mark_debug = "true" *) wire range_frame_valid;
    (* mark_debug = "true" *) wire [5:0] peak_bin;
    (* mark_debug = "true" *) wire [16:0] peak_magnitude;
    wire peak_ok = range_frame_valid && (peak_bin == 6'd5) &&
                   (peak_magnitude >= 17'd8000);

    training_frame_source u_source (
        .clk(clk), .rst(rst), .m_valid(tx_valid), .m_ready(tx_ready),
        .m_last(tx_last), .m_i(tx_i), .m_q(tx_q)
    );
    fft64_axis_wrapper #(.INVERSE(1'b1)) u_tx_ifft (
        .clk(clk), .rst(rst), .s_valid(tx_valid), .s_ready(tx_ready),
        .s_last(tx_last), .s_i(tx_i), .s_q(tx_q),
        .m_valid(ifft_valid), .m_ready(ifft_ready), .m_last(ifft_last),
        .m_i(ifft_i), .m_q(ifft_q)
    );
    cp_insert_axis u_cp_insert (
        .clk(clk), .rst(rst), .s_axis_tvalid(ifft_valid),
        .s_axis_tready(ifft_ready), .s_axis_i(ifft_i), .s_axis_q(ifft_q),
        .m_axis_tready(cp_ready), .m_axis_tvalid(cp_valid),
        .m_axis_tlast(cp_last), .m_axis_i(cp_i), .m_axis_q(cp_q)
    );
    digital_delay_channel_axis #(.DELAY(5)) u_target (
        .clk(clk), .rst(rst), .s_axis_tvalid(cp_valid),
        .s_axis_tready(cp_ready), .s_axis_tlast(cp_last),
        .s_axis_i(cp_i), .s_axis_q(cp_q), .m_axis_tready(delayed_ready),
        .m_axis_tvalid(delayed_valid), .m_axis_tlast(delayed_last),
        .m_axis_i(delayed_i), .m_axis_q(delayed_q)
    );
    cp_remove_axis u_cp_remove (
        .clk(clk), .rst(rst), .s_axis_tvalid(delayed_valid),
        .s_axis_tready(delayed_ready), .s_axis_i(delayed_i),
        .s_axis_q(delayed_q), .m_axis_tready(rx_ready),
        .m_axis_tvalid(rx_valid), .m_axis_tlast(rx_last),
        .m_axis_i(rx_i), .m_axis_q(rx_q)
    );
    fft64_axis_wrapper u_rx_fft (
        .clk(clk), .rst(rst), .s_valid(rx_valid), .s_ready(rx_ready),
        .s_last(rx_last), .s_i(rx_i), .s_q(rx_q), .m_valid(fft_valid),
        .m_ready(fft_ready), .m_last(fft_last), .m_i(fft_i), .m_q(fft_q)
    );
    training_channel_estimator_axis u_estimator (
        .clk(clk), .rst(rst), .s_axis_tvalid(fft_valid),
        .s_axis_tready(fft_ready), .s_axis_tlast(fft_last),
        .s_axis_i(fft_i), .s_axis_q(fft_q), .m_axis_tready(h_ready),
        .m_axis_tvalid(h_valid), .m_axis_tlast(h_last), .m_axis_i(h_i),
        .m_axis_q(h_q)
    );
    fft64_axis_wrapper #(.INVERSE(1'b1)) u_range_ifft (
        .clk(clk), .rst(rst), .s_valid(h_valid), .s_ready(h_ready),
        .s_last(h_last), .s_i(h_i), .s_q(h_q), .m_valid(range_valid),
        .m_ready(1'b1), .m_last(range_last), .m_i(range_i), .m_q(range_q)
    );
    range_peak_detector u_peak (
        .clk(clk), .rst(rst), .s_valid(range_valid), .s_last(range_last),
        .s_i(range_i), .s_q(range_q), .frame_valid(range_frame_valid),
        .last_peak_bin(peak_bin), .last_peak_magnitude(peak_magnitude)
    );

    always @(posedge clk) begin
        if (rst)
            heartbeat <= 27'd0;
        else
            heartbeat <= heartbeat + 1'b1;
    end

    assign led0 = heartbeat[26];
    assign led1 = range_frame_valid;
    assign led2 = peak_ok;
    assign led3 = range_frame_valid && !peak_ok;
endmodule
