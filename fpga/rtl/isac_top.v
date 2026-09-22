`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/22 01:14:34
// Design Name: 
// Module Name: isac_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module isac_top (
    input  wire clk,
    input  wire rst_n,
    output wire led0
);

    reg [26:0] counter;
    wire rst = ~rst_n;          // BTN0 is active-low on PYNQ-Z2
    wire [1:0] symbol_bits = counter[26:25];
    wire symbol_valid = 1'b1;
    wire symbol_out_valid;
    wire signed [15:0] i_symbol;
    wire signed [15:0] q_symbol;
    reg [6:0] tx_index;
    reg [20:0] loop_frames;
    wire signed [15:0] frame_i = $signed({9'd0, tx_index});
    wire signed [15:0] frame_q = -frame_i;
    wire cp_s_ready;
    wire cp_m_valid, cp_m_ready, cp_m_last;
    wire signed [15:0] cp_m_i, cp_m_q;
    wire rx_s_ready, rx_m_valid, rx_m_last;
    wire signed [15:0] rx_m_i, rx_m_q;
    wire fft_s_ready, fft_m_valid, fft_m_last;
    wire signed [15:0] fft_m_i, fft_m_q;
    wire loopback_last = fft_m_valid && fft_m_last;

    // First hardware integration point: the slow counter supplies a repeating
    // four-symbol stream to the QPSK mapper. The LED combines the heartbeat
    // with the mapper quadrant so a programmed board visibly changes state.
    qpsk_mapper u_qpsk_mapper (
        .clk       (clk),
        .rst       (rst),
        .in_valid  (symbol_valid),
        .bits      (symbol_bits),
        .out_valid (symbol_out_valid),
        .i_out     (i_symbol),
        .q_out     (q_symbol)
    );

    // Hardware loopback smoke path: generated samples -> CP insert -> CP
    // remove. The ready/valid interface can later connect to FFT and DMA.
    cp_insert_axis u_cp_insert (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(1'b1), .s_axis_tready(cp_s_ready),
        .s_axis_i(frame_i), .s_axis_q(frame_q),
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
    fft64_axis_wrapper u_fft64 (
        .clk(clk), .rst(rst),
        .s_valid(rx_m_valid), .s_ready(fft_s_ready), .s_last(rx_m_last),
        .s_i(rx_m_i), .s_q(rx_m_q),
        .m_valid(fft_m_valid), .m_ready(1'b1), .m_last(fft_m_last),
        .m_i(fft_m_i), .m_q(fft_m_q)
    );

    always @(posedge clk) begin
        // Keep the visible heartbeat independent of the push-button level.
        // This also makes board bring-up robust when BTN0 is held or floating.
        counter <= counter + 1'b1;
        if (rst) begin
            tx_index <= 7'd0;
            loop_frames <= 21'd0;
        end else begin
            if (cp_s_ready)
                tx_index <= (tx_index == 7'd63) ? 7'd0 : tx_index + 1'b1;
            if (loopback_last)
                loop_frames <= loop_frames + 1'b1;
        end
    end

    assign led0 = ~counter[26] ^ (i_symbol[15] ^ q_symbol[15]) ^ loop_frames[20];

endmodule
