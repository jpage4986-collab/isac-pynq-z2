`timescale 1ns/1ps

// Noise-free reference checker after the 1/64 IFFT and 1/64 FFT schedules.
// The hardware BER counters compare hard decisions against the same fixed
// LFSR sequence used by ofdm_frame_source; no PS or PC computation is needed.
module ofdm_frame_checker (
    input  wire clk,
    input  wire rst,
    input  wire s_valid,
    input  wire s_last,
    input  wire signed [15:0] s_i,
    input  wire signed [15:0] s_q,
    output reg frame_seen,
    output reg data_frame_seen,
    output reg last_frame_ok,
    output reg sticky_error,
    output reg [31:0] frame_count,
    output reg [31:0] data_frame_count,
    output reg [31:0] bit_count,
    output reg [31:0] bit_errors
);
    reg [5:0] bin_index;
    reg data_frame;
    reg [15:0] prbs;
    reg frame_error;
    wire active = (bin_index >= 6'd1 && bin_index <= 6'd26) ||
                  (bin_index >= 6'd38);
    wire pilot = (bin_index == 6'd7) || (bin_index == 6'd21) ||
                 (bin_index == 6'd43) || (bin_index == 6'd57);
    wire data_bin = active && !pilot && data_frame;
    wire feedback = prbs[15] ^ prbs[13] ^ prbs[12] ^ prbs[10];
    wire signed [16:0] actual_i = {s_i[15], s_i};
    wire signed [16:0] actual_q = {s_q[15], s_q};
    wire signed [16:0] expected_i = !active ? 17'sd0 :
        data_bin ? (prbs[1] ? -17'sd181 : 17'sd181) : 17'sd256;
    wire signed [16:0] expected_q =
        data_bin ? (prbs[0] ? -17'sd181 : 17'sd181) : 17'sd0;
    wire signed [16:0] tolerance = data_bin ? 17'sd48 : 17'sd40;
    wire numeric_error = (actual_i < expected_i - tolerance) ||
                         (actual_i > expected_i + tolerance) ||
                         (actual_q < expected_q - tolerance) ||
                         (actual_q > expected_q + tolerance);
    wire sample_error = numeric_error || (s_last != (bin_index == 6'd63));
    wire wrong_i = s_i[15] != prbs[1];
    wire wrong_q = s_q[15] != prbs[0];
    wire [1:0] wrong_bits = {1'b0, wrong_i} + {1'b0, wrong_q};

    always @(posedge clk) begin
        if (rst) begin
            bin_index <= 6'd0;
            data_frame <= 1'b0;
            prbs <= 16'hACE1;
            frame_error <= 1'b0;
            frame_seen <= 1'b0;
            data_frame_seen <= 1'b0;
            last_frame_ok <= 1'b0;
            sticky_error <= 1'b0;
            frame_count <= 32'd0;
            data_frame_count <= 32'd0;
            bit_count <= 32'd0;
            bit_errors <= 32'd0;
        end else if (s_valid) begin
            if (sample_error) begin
                frame_error <= 1'b1;
                sticky_error <= 1'b1;
            end
            if (data_bin) begin
                prbs <= {prbs[14:0], feedback};
                if (bit_count != 32'hFFFFFFFE)
                    bit_count <= bit_count + 2'd2;
                if (bit_errors < 32'hFFFFFFFE)
                    bit_errors <= bit_errors + {30'd0, wrong_bits};
            end
            if (s_last) begin
                frame_seen <= 1'b1;
                last_frame_ok <= !frame_error && !sample_error;
                frame_error <= 1'b0;
                if (frame_count != 32'hFFFFFFFF)
                    frame_count <= frame_count + 1'b1;
                if (data_frame) begin
                    data_frame_seen <= 1'b1;
                    if (data_frame_count != 32'hFFFFFFFF)
                        data_frame_count <= data_frame_count + 1'b1;
                end
                data_frame <= !data_frame;
                bin_index <= 6'd0;
            end else begin
                bin_index <= bin_index + 1'b1;
            end
        end
    end
endmodule
