`timescale 1ns/1ps

// Captures one known training FFT frame and emits a fixed-point estimate of
// H[k] = Y[k] / X[k]. The present training symbol is +16384 on every active
// carrier and the paired scaled FFTs make a no-channel Y[k] about +256.
// Multiplication by 64 maps that nominal channel coefficient to Q14 (+16384).
module training_channel_estimator_axis #(
    parameter integer N_FFT = 64,
    parameter integer DATA_W = 16,
    parameter integer SCALE_SHIFT = 6,
    parameter integer COUNT_W = 6
) (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire s_axis_tlast,
    input  wire signed [DATA_W-1:0] s_axis_i,
    input  wire signed [DATA_W-1:0] s_axis_q,
    input  wire m_axis_tready,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    output wire signed [DATA_W-1:0] m_axis_i,
    output wire signed [DATA_W-1:0] m_axis_q
);
    localparam S_CAPTURE = 1'b0;
    localparam S_OUTPUT = 1'b1;
    reg state;
    reg [COUNT_W-1:0] wr_index, rd_index;
    reg signed [DATA_W-1:0] mem_i [0:N_FFT-1];
    reg signed [DATA_W-1:0] mem_q [0:N_FFT-1];
    wire output_fire = m_axis_tvalid && m_axis_tready;

    assign s_axis_tready = (state == S_CAPTURE);
    assign m_axis_tvalid = (state == S_OUTPUT);
    assign m_axis_tlast = (state == S_OUTPUT) && (rd_index == N_FFT-1);
    assign m_axis_i = mem_i[rd_index] <<< SCALE_SHIFT;
    assign m_axis_q = mem_q[rd_index] <<< SCALE_SHIFT;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_CAPTURE;
            wr_index <= 0;
            rd_index <= 0;
        end else if (state == S_CAPTURE) begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem_i[wr_index] <= s_axis_i;
                mem_q[wr_index] <= s_axis_q;
                if (wr_index == N_FFT-1 && s_axis_tlast) begin
                    wr_index <= 0;
                    rd_index <= 0;
                    state <= S_OUTPUT;
                end else if (wr_index != N_FFT-1) begin
                    wr_index <= wr_index + 1'b1;
                end
            end
        end else if (output_fire) begin
            if (rd_index == N_FFT-1) begin
                rd_index <= 0;
                state <= S_CAPTURE;
            end else begin
                rd_index <= rd_index + 1'b1;
            end
        end
    end
endmodule
