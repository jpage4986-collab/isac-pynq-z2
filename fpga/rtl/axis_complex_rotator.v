`timescale 1ns/1ps

// Three-stage AXI-Stream complex rotator. Input capture, DSP products, and
// complex sum use separate registers; every stage honors backpressure.
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
    reg in_valid, in_last;
    reg signed [DATA_W-1:0] in_i, in_q, in_cos, in_sin;
    reg prod_valid, prod_last;
    reg signed [31:0] prod_ic, prod_qs, prod_is, prod_qc;
    reg out_valid, out_last;
    reg signed [DATA_W-1:0] out_i, out_q;
    wire signed [32:0] rotated_i = {prod_ic[31], prod_ic} - {prod_qs[31], prod_qs};
    wire signed [32:0] rotated_q = {prod_is[31], prod_is} + {prod_qc[31], prod_qc};

    wire advance_out = !out_valid || m_axis_tready;
    wire advance_prod = !prod_valid || advance_out;
    wire advance_in = !in_valid || advance_prod;
    assign s_axis_tready = advance_in;
    assign m_axis_tvalid = out_valid;
    assign m_axis_tlast = out_last;
    assign m_axis_i = out_i;
    assign m_axis_q = out_q;

    always @(posedge clk) begin
        if (rst) begin
            in_valid <= 1'b0;
            in_last <= 1'b0;
            in_i <= 0;
            in_q <= 0;
            in_cos <= 0;
            in_sin <= 0;
            prod_valid <= 1'b0;
            prod_last <= 1'b0;
            prod_ic <= 0;
            prod_qs <= 0;
            prod_is <= 0;
            prod_qc <= 0;
            out_valid <= 1'b0;
            out_last <= 1'b0;
            out_i <= 0;
            out_q <= 0;
        end else begin
            if (advance_out) begin
                out_valid <= prod_valid;
                if (prod_valid) begin
                    out_last <= prod_last;
                    out_i <= rotated_i >>> FRAC_W;
                    out_q <= rotated_q >>> FRAC_W;
                end
            end
            if (advance_prod) begin
                prod_valid <= in_valid;
                if (in_valid) begin
                    prod_last <= in_last;
                    prod_ic <= in_i * in_cos;
                    prod_qs <= in_q * in_sin;
                    prod_is <= in_i * in_sin;
                    prod_qc <= in_q * in_cos;
                end
            end
            if (advance_in) begin
                in_valid <= s_axis_tvalid;
                if (s_axis_tvalid) begin
                    in_last <= s_axis_tlast;
                    in_i <= s_axis_i;
                    in_q <= s_axis_q;
                    in_cos <= cos_q14;
                    in_sin <= sin_q14;
                end
            end
        end
    end
endmodule
