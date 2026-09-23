`timescale 1ns/1ps

// One-sample AXI-Stream complex rotator. cos_q14 and sin_q14 represent
// cos(phi) and sin(phi) in Q2.14. The registered output makes backpressure
// explicit and keeps the channel model reusable by the communication path.
module axis_complex_rotator #(
    parameter integer DATA_W = 16,
    parameter integer FRAC_W = 14
) (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire s_axis_tlast,
    input  wire signed [DATA_W-1:0] s_axis_i,
    input  wire signed [DATA_W-1:0] s_axis_q,
    input  wire signed [DATA_W-1:0] cos_q14,
    input  wire signed [DATA_W-1:0] sin_q14,
    input  wire m_axis_tready,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    output wire signed [DATA_W-1:0] m_axis_i,
    output wire signed [DATA_W-1:0] m_axis_q
);
    reg out_valid, out_last;
    reg signed [DATA_W-1:0] out_i, out_q;
    wire signed [31:0] prod_ic = $signed(s_axis_i) * $signed(cos_q14);
    wire signed [31:0] prod_qs = $signed(s_axis_q) * $signed(sin_q14);
    wire signed [31:0] prod_is = $signed(s_axis_i) * $signed(sin_q14);
    wire signed [31:0] prod_qc = $signed(s_axis_q) * $signed(cos_q14);
    wire signed [32:0] rotated_i = {prod_ic[31], prod_ic} - {prod_qs[31], prod_qs};
    wire signed [32:0] rotated_q = {prod_is[31], prod_is} + {prod_qc[31], prod_qc};

    assign s_axis_tready = !out_valid || m_axis_tready;
    assign m_axis_tvalid = out_valid;
    assign m_axis_tlast = out_last;
    assign m_axis_i = out_i;
    assign m_axis_q = out_q;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
            out_i <= 0;
            out_q <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            out_valid <= 1'b1;
            out_last <= s_axis_tlast;
            out_i <= rotated_i >>> FRAC_W;
            out_q <= rotated_q >>> FRAC_W;
        end else if (out_valid && m_axis_tready) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
        end
    end
endmodule
