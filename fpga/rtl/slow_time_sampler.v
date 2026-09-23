`timescale 1ns/1ps

// Capture the latest completed target gate once per 100 Hz phase-clock tick.
// This deliberately samples the previous stable target phase; downstream
// processing receives exactly one sample per tick once the first range frame
// has completed.
module slow_time_sampler (
    input wire clk,
    input wire rst,
    input wire sample_tick,
    input wire gate_valid,
    input wire signed [15:0] gate_i,
    input wire signed [15:0] gate_q,
    output reg slow_valid,
    output reg signed [15:0] slow_i,
    output reg signed [15:0] slow_q,
    output reg [31:0] sample_count
);
    always @(posedge clk) begin
        if (rst) begin
            slow_valid <= 1'b0;
            slow_i <= 0;
            slow_q <= 0;
            sample_count <= 0;
        end else begin
            slow_valid <= 1'b0;
            if (sample_tick && gate_valid) begin
                slow_i <= gate_i;
                slow_q <= gate_q;
                slow_valid <= 1'b1;
                if (sample_count != 32'hFFFFFFFF)
                    sample_count <= sample_count + 1'b1;
            end
        end
    end
endmodule
