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

    always @(posedge clk) begin
        if (rst_n)
            counter <= 27'd0;
        else
            counter <= counter + 1'b1;
    end

    assign led0 = ~counter[26];

endmodule
