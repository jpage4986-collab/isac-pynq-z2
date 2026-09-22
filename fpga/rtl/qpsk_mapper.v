`timescale 1ns/1ps
// QPSK mapper: two input bits to signed Q1.15 I/Q symbols.
// Mapping matches model/ofdm.py::qpsk_mod.
module qpsk_mapper #(
    parameter integer OUT_WIDTH = 16,
    parameter integer QPSK_MAG = 23170
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   in_valid,
    input  wire [1:0]             bits,
    output reg                    out_valid,
    output reg signed [OUT_WIDTH-1:0] i_out,
    output reg signed [OUT_WIDTH-1:0] q_out
);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            i_out     <= {OUT_WIDTH{1'b0}};
            q_out     <= {OUT_WIDTH{1'b0}};
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                case (bits)
                    2'b00: begin i_out <=  QPSK_MAG; q_out <=  QPSK_MAG; end
                    2'b01: begin i_out <=  QPSK_MAG; q_out <= -QPSK_MAG; end
                    2'b10: begin i_out <= -QPSK_MAG; q_out <=  QPSK_MAG; end
                    default: begin i_out <= -QPSK_MAG; q_out <= -QPSK_MAG; end
                endcase
            end
        end
    end
endmodule
