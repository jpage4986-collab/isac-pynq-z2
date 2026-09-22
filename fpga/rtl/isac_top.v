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

    always @(posedge clk) begin
        if (!rst_n)
            counter <= 27'd0;
        else
            counter <= counter + 1'b1;
    end

    assign led0 = ~counter[26] ^ (i_symbol[15] ^ q_symbol[15]);

endmodule
