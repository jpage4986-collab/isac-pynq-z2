`timescale 1ns/1ps

// PL-only deterministic communication loopback. RF, PS/DMA and sensing are
// deliberately outside this stage; status LEDs are driven by FPGA counters.
module isac_top (
    input  wire clk,
    input  wire btn0,
    output wire led0,
    output wire led1,
    output wire led2,
    output wire led3
);
    wire rst = btn0; // PYNQ-Z2 push button is high while pressed
    reg [26:0] heartbeat;
    wire tx_valid, tx_ready, tx_last;
    wire signed [15:0] tx_i, tx_q;
    wire ifft_valid, ifft_ready, ifft_last;
    wire signed [15:0] ifft_i, ifft_q;
    wire cp_valid, cp_ready, cp_last;
    wire signed [15:0] cp_i, cp_q;
    wire rx_valid, rx_ready, rx_last;
    wire signed [15:0] rx_i, rx_q;
    wire fft_valid, fft_last;
    wire signed [15:0] fft_i, fft_q;
    wire frame_seen, data_frame_seen, last_frame_ok, sticky_error;
    (* mark_debug = "true" *) wire [31:0] frame_count;
    (* mark_debug = "true" *) wire [31:0] data_frame_count;
    (* mark_debug = "true" *) wire [31:0] bit_count;
    (* mark_debug = "true" *) wire [31:0] bit_errors;

    ofdm_frame_source u_source (
        .clk(clk), .rst(rst),
        .m_valid(tx_valid), .m_ready(tx_ready), .m_last(tx_last),
        .m_i(tx_i), .m_q(tx_q)
    );
    fft64_axis_wrapper #(.INVERSE(1'b1)) u_ifft (
        .clk(clk), .rst(rst),
        .s_valid(tx_valid), .s_ready(tx_ready), .s_last(tx_last),
        .s_i(tx_i), .s_q(tx_q),
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
        .clk(clk), .rst(rst),
        .s_valid(rx_valid), .s_ready(rx_ready), .s_last(rx_last),
        .s_i(rx_i), .s_q(rx_q),
        .m_valid(fft_valid), .m_ready(1'b1), .m_last(fft_last),
        .m_i(fft_i), .m_q(fft_q)
    );
    ofdm_frame_checker u_checker (
        .clk(clk), .rst(rst), .s_valid(fft_valid), .s_last(fft_last),
        .s_i(fft_i), .s_q(fft_q),
        .frame_seen(frame_seen), .data_frame_seen(data_frame_seen),
        .last_frame_ok(last_frame_ok), .sticky_error(sticky_error),
        .frame_count(frame_count), .data_frame_count(data_frame_count),
        .bit_count(bit_count), .bit_errors(bit_errors)
    );

    always @(posedge clk)
        heartbeat <= heartbeat + 1'b1;

    assign led0 = heartbeat[26];
    assign led1 = data_frame_seen && last_frame_ok && !sticky_error &&
                  (bit_count != 32'd0) && (bit_errors == 32'd0);
    assign led2 = frame_seen && (frame_count != 32'd0);
    assign led3 = sticky_error;
endmodule
