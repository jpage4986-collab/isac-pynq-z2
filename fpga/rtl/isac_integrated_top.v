`timescale 1ns/1ps

// One alternating training/QPSK stream crosses the same 5-sample digital
// target. A frame-aligned 100 Hz phasor adds structural micro-vibration.
module isac_integrated_top #(
    parameter integer SLOW_DIV = 1250000,
    parameter [31:0] PHASE_STEP = 32'd103079215
) (
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
    wire channel_valid, channel_ready, channel_last;
    wire signed [15:0] channel_i, channel_q;
    wire rx_valid, rx_ready, rx_last;
    wire signed [15:0] rx_i, rx_q;
    wire fft_valid, fft_ready, fft_last;
    wire signed [15:0] fft_i, fft_q;
    wire comm_valid, comm_ready, comm_last;
    wire signed [15:0] comm_i, comm_q;
    wire train_valid, train_ready, train_last;
    wire signed [15:0] train_i, train_q;
    wire equalized_valid, equalized_last;
    wire signed [15:0] equalized_i, equalized_q;
    wire h_valid, h_ready, h_last;
    wire signed [15:0] h_i, h_q;
    wire range_valid, range_last;
    wire signed [15:0] range_i, range_q;
    wire signed [15:0] channel_cos_q14, channel_sin_q14;
    (* mark_debug = "true" *) wire slow_sample_tick;
    wire frame_seen, data_frame_seen, last_frame_ok, sticky_error;
    (* mark_debug = "true" *) wire [31:0] frame_count;
    (* mark_debug = "true" *) wire [31:0] data_frame_count;
    (* mark_debug = "true" *) wire [31:0] bit_count;
    (* mark_debug = "true" *) wire [31:0] bit_errors;
    (* mark_debug = "true" *) wire range_frame_valid;
    (* mark_debug = "true" *) wire [5:0] peak_bin;
    (* mark_debug = "true" *) wire [16:0] peak_magnitude;
    (* mark_debug = "true" *) wire gate_valid;
    (* mark_debug = "true" *) wire signed [15:0] gate_i, gate_q;
    (* mark_debug = "true" *) wire slow_valid;
    (* mark_debug = "true" *) wire signed [15:0] slow_i, slow_q;
    (* mark_debug = "true" *) wire [31:0] slow_sample_count;
    (* mark_debug = "true" *) wire phase_product_valid;
    (* mark_debug = "true" *) wire signed [32:0] phase_product_i, phase_product_q;
    wire range_ok = range_frame_valid && (peak_bin == 6'd5) &&
                    (peak_magnitude >= 17'd8000);

    ofdm_frame_source u_source (
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
    digital_delay_channel_axis #(.DELAY(5)) u_target_delay (
        .clk(clk), .rst(rst), .s_axis_tvalid(cp_valid),
        .s_axis_tready(cp_ready), .s_axis_tlast(cp_last), .s_axis_i(cp_i),
        .s_axis_q(cp_q), .m_axis_tready(delayed_ready),
        .m_axis_tvalid(delayed_valid), .m_axis_tlast(delayed_last),
        .m_axis_i(delayed_i), .m_axis_q(delayed_q)
    );
    vibration_phasor_q14 #(.SLOW_DIV(SLOW_DIV), .PHASE_STEP(PHASE_STEP))
        u_vibration_phasor (
        .clk(clk), .rst(rst),
        .frame_boundary(delayed_valid && delayed_ready && delayed_last),
        .sample_tick(slow_sample_tick),
        .cos_q14(channel_cos_q14), .sin_q14(channel_sin_q14)
    );
    axis_complex_rotator u_channel_gain (
        .clk(clk), .rst(rst), .s_axis_tvalid(delayed_valid),
        .s_axis_tready(delayed_ready), .s_axis_tlast(delayed_last),
        .s_axis_i(delayed_i), .s_axis_q(delayed_q),
        .cos_q14(channel_cos_q14), .sin_q14(channel_sin_q14),
        .m_axis_tready(channel_ready), .m_axis_tvalid(channel_valid),
        .m_axis_tlast(channel_last), .m_axis_i(channel_i), .m_axis_q(channel_q)
    );
    cp_remove_axis u_cp_remove (
        .clk(clk), .rst(rst), .s_axis_tvalid(channel_valid),
        .s_axis_tready(channel_ready), .s_axis_i(channel_i), .s_axis_q(channel_q),
        .m_axis_tready(rx_ready), .m_axis_tvalid(rx_valid),
        .m_axis_tlast(rx_last), .m_axis_i(rx_i), .m_axis_q(rx_q)
    );
    fft64_axis_wrapper u_rx_fft (
        .clk(clk), .rst(rst), .s_valid(rx_valid), .s_ready(rx_ready),
        .s_last(rx_last), .s_i(rx_i), .s_q(rx_q), .m_valid(fft_valid),
        .m_ready(fft_ready), .m_last(fft_last), .m_i(fft_i), .m_q(fft_q)
    );
    ofdm_training_broadcaster u_broadcast (
        .clk(clk), .rst(rst), .s_axis_tvalid(fft_valid), .s_axis_tready(fft_ready),
        .s_axis_tlast(fft_last), .s_axis_i(fft_i), .s_axis_q(fft_q),
        .comm_axis_tready(comm_ready), .comm_axis_tvalid(comm_valid),
        .comm_axis_tlast(comm_last), .comm_axis_i(comm_i), .comm_axis_q(comm_q),
        .training_axis_tready(train_ready), .training_axis_tvalid(train_valid),
        .training_axis_tlast(train_last), .training_axis_i(train_i),
        .training_axis_q(train_q)
    );
    delay5_equalizer_axis u_comm_equalizer (
        .clk(clk), .rst(rst), .s_axis_tvalid(comm_valid), .s_axis_tready(comm_ready),
        .s_axis_tlast(comm_last), .s_axis_i(comm_i), .s_axis_q(comm_q),
        .m_axis_tready(1'b1), .m_axis_tvalid(equalized_valid),
        .m_axis_tlast(equalized_last), .m_axis_i(equalized_i), .m_axis_q(equalized_q)
    );
    ofdm_frame_checker u_checker (
        .clk(clk), .rst(rst), .s_valid(equalized_valid), .s_last(equalized_last),
        .s_i(equalized_i), .s_q(equalized_q), .frame_seen(frame_seen),
        .data_frame_seen(data_frame_seen), .last_frame_ok(last_frame_ok),
        .sticky_error(sticky_error), .frame_count(frame_count),
        .data_frame_count(data_frame_count), .bit_count(bit_count),
        .bit_errors(bit_errors)
    );
    training_channel_estimator_axis u_estimator (
        .clk(clk), .rst(rst), .s_axis_tvalid(train_valid),
        .s_axis_tready(train_ready), .s_axis_tlast(train_last),
        .s_axis_i(train_i), .s_axis_q(train_q), .m_axis_tready(h_ready),
        .m_axis_tvalid(h_valid), .m_axis_tlast(h_last), .m_axis_i(h_i), .m_axis_q(h_q)
    );
    fft64_axis_wrapper #(.INVERSE(1'b1)) u_range_ifft (
        .clk(clk), .rst(rst), .s_valid(h_valid), .s_ready(h_ready),
        .s_last(h_last), .s_i(h_i), .s_q(h_q), .m_valid(range_valid),
        .m_ready(1'b1), .m_last(range_last), .m_i(range_i), .m_q(range_q)
    );
    range_peak_detector u_range_peak (
        .clk(clk), .rst(rst), .s_valid(range_valid), .s_last(range_last),
        .s_i(range_i), .s_q(range_q), .frame_valid(range_frame_valid),
        .last_peak_bin(peak_bin), .last_peak_magnitude(peak_magnitude)
    );
    range_gate_sampler #(.GATE_BIN(6'd5)) u_target_gate (
        .clk(clk), .rst(rst), .s_valid(range_valid), .s_last(range_last),
        .s_i(range_i), .s_q(range_q), .gate_valid(gate_valid),
        .gate_i(gate_i), .gate_q(gate_q)
    );
    slow_time_sampler u_slow_sampler (
        .clk(clk), .rst(rst), .sample_tick(slow_sample_tick),
        .gate_valid(gate_valid), .gate_i(gate_i), .gate_q(gate_q),
        .slow_valid(slow_valid), .slow_i(slow_i), .slow_q(slow_q),
        .sample_count(slow_sample_count)
    );
    slow_phase_product u_phase_product (
        .clk(clk), .rst(rst), .slow_valid(slow_valid),
        .slow_i(slow_i), .slow_q(slow_q),
        .product_valid(phase_product_valid),
        .product_i(phase_product_i), .product_q(phase_product_q)
    );

    always @(posedge clk) begin
        if (rst)
            heartbeat <= 0;
        else
            heartbeat <= heartbeat + 1'b1;
    end

    assign led0 = heartbeat[26];
    assign led1 = data_frame_seen && (bit_count != 0) && (bit_errors == 0) && !sticky_error;
    assign led2 = range_ok;
    assign led3 = sticky_error || (range_frame_valid && !range_ok);
endmodule
