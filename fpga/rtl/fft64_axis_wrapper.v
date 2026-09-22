`timescale 1ns/1ps
// Thin ready/valid wrapper around the Vivado XFFT 9.1 64-point core.
// Complex samples are exposed as separate signed I/Q channels; the XFFT
// native 32-bit stream packs {imaginary, real}.
module fft64_axis_wrapper #(
    parameter INVERSE = 1'b0
) (
    input  wire clk,
    input  wire rst,
    input  wire s_valid,
    output wire s_ready,
    input  wire s_last,
    input  wire signed [15:0] s_i,
    input  wire signed [15:0] s_q,
    output wire m_valid,
    input  wire m_ready,
    output wire m_last,
    output wire signed [15:0] m_i,
    output wire signed [15:0] m_q
);
    reg config_sent;
    wire config_valid = !config_sent;
    wire config_ready;
    // SCALE_SCH = [2,2,2] => six right shifts across three radix-4 stages
    // (1/64 total). FWD_INV occupies bit 0; SCALE_SCH occupies bits [6:1].
    wire [7:0] config_data = INVERSE ? 8'h54 : 8'h55;
    wire [31:0] fft_in = {s_q, s_i};
    wire [31:0] fft_out;
    wire fft_in_ready;

    assign s_ready = config_sent && fft_in_ready;
    assign m_i = fft_out[15:0];
    assign m_q = fft_out[31:16];

    always @(posedge clk) begin
        if (rst)
            config_sent <= 1'b0;
        else if (config_valid && config_ready)
            config_sent <= 1'b1;
    end

    xfft_64 u_xfft (
        .aclk(clk),
        .aresetn(~rst),
        .s_axis_config_tdata(config_data),
        .s_axis_config_tvalid(config_valid),
        .s_axis_config_tready(config_ready),
        .s_axis_data_tdata(fft_in),
        .s_axis_data_tvalid(s_valid && config_sent),
        .s_axis_data_tready(fft_in_ready),
        .s_axis_data_tlast(s_last),
        .m_axis_data_tdata(fft_out),
        .m_axis_data_tvalid(m_valid),
        .m_axis_data_tready(m_ready),
        .m_axis_data_tlast(m_last),
        .event_frame_started(),
        .event_tlast_unexpected(),
        .event_tlast_missing(),
        .event_status_channel_halt(),
        .event_data_in_channel_halt(),
        .event_data_out_channel_halt()
    );
endmodule
