`timescale 1ns/1ps
// Remove the first CP_LEN samples from one complex OFDM symbol.
module cp_remove #(
    parameter integer N_FFT   = 64,
    parameter integer CP_LEN  = 16,
    parameter integer DATA_W  = 16,
    parameter integer COUNT_W = 7
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     in_valid,
    output wire                     in_ready,
    input  wire signed [DATA_W-1:0] in_i,
    input  wire signed [DATA_W-1:0] in_q,
    output wire                     out_valid,
    output wire signed [DATA_W-1:0] out_i,
    output wire signed [DATA_W-1:0] out_q,
    output wire                     frame_done
);
    localparam integer TOTAL_LEN = N_FFT + CP_LEN;
    localparam [1:0] S_INPUT = 2'd0;
    localparam [1:0] S_DONE  = 2'd1;
    reg [1:0] state;
    reg [COUNT_W-1:0] in_index;
    reg signed [DATA_W-1:0] out_i_reg, out_q_reg;
    reg out_valid_reg, frame_done_reg;

    assign in_ready = (state == S_INPUT);
    assign out_valid = out_valid_reg;
    assign out_i = out_i_reg;
    assign out_q = out_q_reg;
    assign frame_done = frame_done_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_INPUT;
            in_index <= {COUNT_W{1'b0}};
            out_i_reg <= {DATA_W{1'b0}};
            out_q_reg <= {DATA_W{1'b0}};
            out_valid_reg <= 1'b0;
            frame_done_reg <= 1'b0;
        end else begin
            out_valid_reg <= 1'b0;
            frame_done_reg <= 1'b0;
            if (state == S_INPUT && in_valid) begin
                if (in_index >= CP_LEN) begin
                    out_i_reg <= in_i;
                    out_q_reg <= in_q;
                    out_valid_reg <= 1'b1;
                end
                if (in_index == TOTAL_LEN-1) begin
                    frame_done_reg <= 1'b1;
                    state <= S_DONE;
                end else begin
                    in_index <= in_index + 1'b1;
                end
            end else if (state == S_DONE) begin
                // Accept a new frame on the following cycle.
                in_index <= {COUNT_W{1'b0}};
                state <= S_INPUT;
            end
        end
    end
endmodule
