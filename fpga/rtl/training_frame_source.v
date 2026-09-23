`timescale 1ns/1ps

// Repeats the known BPSK training OFDM symbol used by the sensing demo.
// Active bins carry +16384 and DC/guard bins carry zero.
module training_frame_source (
    input  wire clk,
    input  wire rst,
    output wire m_valid,
    input  wire m_ready,
    output wire m_last,
    output wire signed [15:0] m_i,
    output wire signed [15:0] m_q
);
    reg [5:0] bin_index;
    wire active = (bin_index >= 6'd1 && bin_index <= 6'd26) ||
                  (bin_index >= 6'd38);

    assign m_valid = !rst;
    assign m_last = (bin_index == 6'd63);
    assign m_i = active ? 16'sd16384 : 16'sd0;
    assign m_q = 16'sd0;

    always @(posedge clk) begin
        if (rst)
            bin_index <= 6'd0;
        else if (m_valid && m_ready) begin
            if (m_last)
                bin_index <= 6'd0;
            else
                bin_index <= bin_index + 1'b1;
        end
    end
endmodule
