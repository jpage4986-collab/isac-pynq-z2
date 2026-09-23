`timescale 1ns/1ps

// Hold the complex value at a selected delay bin from each 64-point range
// profile. This retains phase information that a magnitude-only peak loses.
module range_gate_sampler #(
    parameter [5:0] GATE_BIN = 6'd5
) (
    input wire clk,
    input wire rst,
    input wire s_valid,
    input wire s_last,
    input wire signed [15:0] s_i,
    input wire signed [15:0] s_q,
    output reg gate_valid,
    output reg signed [15:0] gate_i,
    output reg signed [15:0] gate_q
);
    reg [5:0] bin_index;
    reg signed [15:0] candidate_i, candidate_q;

    always @(posedge clk) begin
        if (rst) begin
            bin_index <= 0;
            candidate_i <= 0;
            candidate_q <= 0;
            gate_valid <= 1'b0;
            gate_i <= 0;
            gate_q <= 0;
        end else if (s_valid) begin
            if (bin_index == GATE_BIN) begin
                candidate_i <= s_i;
                candidate_q <= s_q;
            end
            if (s_last) begin
                gate_valid <= 1'b1;
                gate_i <= (bin_index == GATE_BIN) ? s_i : candidate_i;
                gate_q <= (bin_index == GATE_BIN) ? s_q : candidate_q;
                bin_index <= 0;
            end else begin
                bin_index <= bin_index + 1'b1;
            end
        end
    end
endmodule
