`timescale 1ns/1ps

// Per-sample z[m] * conj(z[m-1]). Its imaginary/real ratio is the incremental
// target phase for displacements much smaller than one carrier wavelength.
// Two registered arithmetic stages keep the 125 MHz path short.
module slow_phase_product (
    input wire clk,
    input wire rst,
    input wire slow_valid,
    input wire signed [15:0] slow_i,
    input wire signed [15:0] slow_q,
    output reg product_valid,
    output reg signed [32:0] product_i,
    output reg signed [32:0] product_q
);
    reg have_previous;
    reg signed [15:0] previous_i, previous_q;
    reg stage_valid;
    reg signed [31:0] ii, qq, qi, iq;

    always @(posedge clk) begin
        if (rst) begin
            have_previous <= 1'b0;
            previous_i <= 0;
            previous_q <= 0;
            stage_valid <= 1'b0;
            product_valid <= 1'b0;
            ii <= 0;
            qq <= 0;
            qi <= 0;
            iq <= 0;
            product_i <= 0;
            product_q <= 0;
        end else begin
            product_valid <= stage_valid;
            if (stage_valid) begin
                product_i <= {ii[31], ii} + {qq[31], qq};
                product_q <= {qi[31], qi} - {iq[31], iq};
            end
            stage_valid <= slow_valid && have_previous;
            if (slow_valid) begin
                ii <= $signed(slow_i) * $signed(previous_i);
                qq <= $signed(slow_q) * $signed(previous_q);
                qi <= $signed(slow_q) * $signed(previous_i);
                iq <= $signed(slow_i) * $signed(previous_q);
                previous_i <= slow_i;
                previous_q <= slow_q;
                have_previous <= 1'b1;
            end
        end
    end
endmodule
