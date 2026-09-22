`timescale 1ns/1ps
// One-frame cyclic-prefix inserter for complex signed samples.
// Capture exactly N_FFT samples, then emit the last CP_LEN samples followed
// by the complete useful symbol. The first version deliberately has no
// output back-pressure so it is easy to compare with the Python model.
module cp_insert #(
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

    localparam integer OUT_LEN = N_FFT + CP_LEN;
    localparam integer OUT_W   = 8;
    localparam [1:0] S_CAPTURE = 2'd0;
    localparam [1:0] S_OUTPUT  = 2'd1;

    reg [1:0] state;
    reg [COUNT_W-1:0] wr_index;
    reg [OUT_W-1:0] rd_index;
    reg signed [DATA_W-1:0] mem_i [0:N_FFT-1];
    reg signed [DATA_W-1:0] mem_q [0:N_FFT-1];

    wire [COUNT_W-1:0] source_index =
        (rd_index < CP_LEN) ? (N_FFT - CP_LEN + rd_index) : (rd_index - CP_LEN);

    assign in_ready   = (state == S_CAPTURE);
    assign out_valid  = (state == S_OUTPUT);
    assign out_i      = mem_i[source_index];
    assign out_q      = mem_q[source_index];
    assign frame_done = (state == S_OUTPUT) && (rd_index == OUT_LEN-1);

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_CAPTURE;
            wr_index <= {COUNT_W{1'b0}};
            rd_index <= {OUT_W{1'b0}};
        end else begin
            case (state)
                S_CAPTURE: begin
                    if (in_valid) begin
                        mem_i[wr_index] <= in_i;
                        mem_q[wr_index] <= in_q;
                        if (wr_index == N_FFT-1) begin
                            wr_index <= {COUNT_W{1'b0}};
                            rd_index <= {OUT_W{1'b0}};
                            state <= S_OUTPUT;
                        end else begin
                            wr_index <= wr_index + 1'b1;
                        end
                    end
                end
                S_OUTPUT: begin
                    if (rd_index == OUT_LEN-1) begin
                        rd_index <= {OUT_W{1'b0}};
                        state <= S_CAPTURE;
                    end else begin
                        rd_index <= rd_index + 1'b1;
                    end
                end
                default: state <= S_CAPTURE;
            endcase
        end
    end
endmodule
