`timescale 1ns/1ps
// AXI-Stream style CP inserter. Complex I/Q are separate signed channels.
// The output advances only on m_axis_tvalid && m_axis_tready.
module cp_insert_axis #(
    parameter integer N_FFT  = 64,
    parameter integer CP_LEN = 16,
    parameter integer DATA_W = 16,
    parameter integer COUNT_W = 7
) (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire signed [DATA_W-1:0] s_axis_i,
    input  wire signed [DATA_W-1:0] s_axis_q,
    input  wire m_axis_tready,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    output wire signed [DATA_W-1:0] m_axis_i,
    output wire signed [DATA_W-1:0] m_axis_q
);
    localparam integer OUT_LEN = N_FFT + CP_LEN;
    localparam [1:0] S_CAPTURE = 2'd0;
    localparam [1:0] S_OUTPUT  = 2'd1;
    reg [1:0] state;
    reg [COUNT_W-1:0] wr_index;
    reg [COUNT_W:0] rd_index;
    reg signed [DATA_W-1:0] mem_i [0:N_FFT-1];
    reg signed [DATA_W-1:0] mem_q [0:N_FFT-1];
    wire [COUNT_W-1:0] source_index =
        (rd_index < CP_LEN) ? (N_FFT - CP_LEN + rd_index) : (rd_index - CP_LEN);
    wire output_fire = m_axis_tvalid && m_axis_tready;

    assign s_axis_tready = (state == S_CAPTURE);
    assign m_axis_tvalid = (state == S_OUTPUT);
    assign m_axis_tlast  = (state == S_OUTPUT) && (rd_index == OUT_LEN-1);
    assign m_axis_i = mem_i[source_index];
    assign m_axis_q = mem_q[source_index];

    always @(posedge clk) begin
        if (rst) begin
            state <= S_CAPTURE;
            wr_index <= {COUNT_W{1'b0}};
            rd_index <= {(COUNT_W+1){1'b0}};
        end else begin
            case (state)
                S_CAPTURE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        mem_i[wr_index] <= s_axis_i;
                        mem_q[wr_index] <= s_axis_q;
                        if (wr_index == N_FFT-1) begin
                            wr_index <= {COUNT_W{1'b0}};
                            rd_index <= {(COUNT_W+1){1'b0}};
                            state <= S_OUTPUT;
                        end else begin
                            wr_index <= wr_index + 1'b1;
                        end
                    end
                end
                S_OUTPUT: begin
                    if (output_fire) begin
                        if (rd_index == OUT_LEN-1) begin
                            rd_index <= {(COUNT_W+1){1'b0}};
                            state <= S_CAPTURE;
                        end else begin
                            rd_index <= rd_index + 1'b1;
                        end
                    end
                end
                default: state <= S_CAPTURE;
            endcase
        end
    end
endmodule
