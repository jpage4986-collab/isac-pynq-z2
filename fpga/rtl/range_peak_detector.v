`timescale 1ns/1ps

// Finds the strongest delay bin in one inverse-FFT range profile. The metric
// |I|+|Q| avoids a multiplier and is sufficient for the first single-target
// digital channel. frame_valid is held until reset so it can be observed by ILA.
module range_peak_detector #(
    parameter integer DATA_W = 16,
    parameter integer COUNT_W = 6
) (
    input wire clk,
    input wire rst,
    input wire s_valid,
    input wire s_last,
    input wire signed [DATA_W-1:0] s_i,
    input wire signed [DATA_W-1:0] s_q,
    output reg frame_valid,
    output reg [COUNT_W-1:0] last_peak_bin,
    output reg [DATA_W:0] last_peak_magnitude
);
    reg [COUNT_W-1:0] bin_index, candidate_bin;
    reg [DATA_W:0] candidate_magnitude;
    wire [DATA_W-1:0] abs_i = s_i[DATA_W-1] ? (~s_i + 1'b1) : s_i;
    wire [DATA_W-1:0] abs_q = s_q[DATA_W-1] ? (~s_q + 1'b1) : s_q;
    wire [DATA_W:0] sample_magnitude = {1'b0, abs_i} + {1'b0, abs_q};

    always @(posedge clk) begin
        if (rst) begin
            frame_valid <= 1'b0;
            last_peak_bin <= 0;
            last_peak_magnitude <= 0;
            bin_index <= 0;
            candidate_bin <= 0;
            candidate_magnitude <= 0;
        end else if (s_valid) begin
            if (sample_magnitude >= candidate_magnitude) begin
                candidate_magnitude <= sample_magnitude;
                candidate_bin <= bin_index;
            end
            if (s_last) begin
                frame_valid <= 1'b1;
                if (sample_magnitude >= candidate_magnitude) begin
                    last_peak_bin <= bin_index;
                    last_peak_magnitude <= sample_magnitude;
                end else begin
                    last_peak_bin <= candidate_bin;
                    last_peak_magnitude <= candidate_magnitude;
                end
                bin_index <= 0;
                candidate_bin <= 0;
                candidate_magnitude <= 0;
            end else begin
                bin_index <= bin_index + 1'b1;
            end
        end
    end
endmodule
