`timescale 1ns/1ps
// AXI-Stream style CP remover. The first CP_LEN accepted samples are
// discarded; each following sample is held until the downstream accepts it.
module cp_remove_axis #(
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
    localparam integer TOTAL_LEN = N_FFT + CP_LEN;
    reg [COUNT_W-1:0] in_index;
    reg pending_valid, pending_last;
    reg signed [DATA_W-1:0] pending_i, pending_q;
    wire output_fire = pending_valid && m_axis_tready;

    assign s_axis_tready = !pending_valid;
    assign m_axis_tvalid = pending_valid;
    assign m_axis_tlast  = pending_last;
    assign m_axis_i      = pending_i;
    assign m_axis_q      = pending_q;

    always @(posedge clk) begin
        if (rst) begin
            in_index <= {COUNT_W{1'b0}};
            pending_valid <= 1'b0;
            pending_last <= 1'b0;
            pending_i <= {DATA_W{1'b0}};
            pending_q <= {DATA_W{1'b0}};
        end else begin
            if (output_fire) begin
                pending_valid <= 1'b0;
                if (pending_last) begin
                    in_index <= {COUNT_W{1'b0}};
                    pending_last <= 1'b0;
                end
            end
            if (s_axis_tvalid && s_axis_tready) begin
                if (in_index >= CP_LEN) begin
                    pending_i <= s_axis_i;
                    pending_q <= s_axis_q;
                    pending_valid <= 1'b1;
                    pending_last <= (in_index == TOTAL_LEN-1);
                end
                if (in_index == TOTAL_LEN-1)
                    in_index <= {COUNT_W{1'b0}};
                else
                    in_index <= in_index + 1'b1;
            end
        end
    end
endmodule
