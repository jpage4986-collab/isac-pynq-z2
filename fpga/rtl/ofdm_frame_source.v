`timescale 1ns/1ps

// Repeating known OFDM frames: one BPSK training frame, then one QPSK frame.
// The 52 active bins are -26..-1 and 1..26; four QPSK-frame pilots are
// -21, -7, 7 and 21. A fixed LFSR makes the 48 data-bin symbols reproducible.
module ofdm_frame_source (
    input  wire clk,
    input  wire rst,
    output wire m_valid,
    input  wire m_ready,
    output wire m_last,
    output wire signed [15:0] m_i,
    output wire signed [15:0] m_q
);
    reg [5:0] bin_index;
    reg data_frame;
    reg [15:0] prbs;
    wire active = (bin_index >= 6'd1 && bin_index <= 6'd26) ||
                  (bin_index >= 6'd38);
    wire pilot = (bin_index == 6'd7) || (bin_index == 6'd21) ||
                 (bin_index == 6'd43) || (bin_index == 6'd57);
    wire data_bin = active && !pilot && data_frame;
    wire feedback = prbs[15] ^ prbs[13] ^ prbs[12] ^ prbs[10];

    assign m_valid = !rst;
    assign m_last = (bin_index == 6'd63);
    assign m_i = !active ? 16'sd0 :
                 data_bin ? (prbs[1] ? -16'sd11585 : 16'sd11585) : 16'sd16384;
    assign m_q = data_bin ? (prbs[0] ? -16'sd11585 : 16'sd11585) : 16'sd0;

    always @(posedge clk) begin
        if (rst) begin
            bin_index <= 6'd0;
            data_frame <= 1'b0;
            prbs <= 16'hACE1;
        end else if (m_valid && m_ready) begin
            if (data_bin)
                prbs <= {prbs[14:0], feedback};
            if (m_last) begin
                bin_index <= 6'd0;
                data_frame <= !data_frame;
            end else begin
                bin_index <= bin_index + 1'b1;
            end
        end
    end
endmodule
