`timescale 1ns/1ps

// One-frame deterministic echo channel. It delays an 80-sample CP-OFDM frame
// without moving TLAST: the leading DELAY samples are zero and the remainder
// is the earlier input. When DELAY <= CP_LEN, the receiver's 64-sample useful
// window sees a circular delay and therefore a linear phase ramp across bins.
module digital_delay_channel_axis #(
    parameter integer FRAME_LEN = 80,
    parameter integer DELAY = 5,
    parameter integer DATA_W = 16,
    parameter integer COUNT_W = 7
) (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire s_axis_tlast,
    input  wire signed [DATA_W-1:0] s_axis_i,
    input  wire signed [DATA_W-1:0] s_axis_q,
    input  wire m_axis_tready,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    output wire signed [DATA_W-1:0] m_axis_i,
    output wire signed [DATA_W-1:0] m_axis_q
);
    localparam S_CAPTURE = 1'b0;
    localparam S_OUTPUT = 1'b1;
    reg state;
    reg [COUNT_W-1:0] wr_index, rd_index;
    reg signed [DATA_W-1:0] mem_i [0:FRAME_LEN-1];
    reg signed [DATA_W-1:0] mem_q [0:FRAME_LEN-1];
    wire output_fire = m_axis_tvalid && m_axis_tready;
    wire delayed_region = rd_index >= DELAY;
    wire [COUNT_W-1:0] source_index = rd_index - DELAY;

    initial begin
        if (DELAY < 0 || DELAY >= FRAME_LEN)
            $error("DELAY must be in [0, FRAME_LEN)");
    end

    assign s_axis_tready = (state == S_CAPTURE);
    assign m_axis_tvalid = (state == S_OUTPUT);
    assign m_axis_tlast = (state == S_OUTPUT) && (rd_index == FRAME_LEN-1);
    assign m_axis_i = delayed_region ? mem_i[source_index] : {DATA_W{1'b0}};
    assign m_axis_q = delayed_region ? mem_q[source_index] : {DATA_W{1'b0}};

    always @(posedge clk) begin
        if (rst) begin
            state <= S_CAPTURE;
            wr_index <= 0;
            rd_index <= 0;
        end else if (state == S_CAPTURE) begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem_i[wr_index] <= s_axis_i;
                mem_q[wr_index] <= s_axis_q;
                // An early TLAST is ignored. If TLAST is missing at the final
                // location, keep overwriting that location until the sender
                // supplies a valid frame end instead of indexing past memory.
                if (wr_index == FRAME_LEN-1 && s_axis_tlast) begin
                    wr_index <= 0;
                    rd_index <= 0;
                    state <= S_OUTPUT;
                end else if (wr_index != FRAME_LEN-1) begin
                    wr_index <= wr_index + 1'b1;
                end
            end
        end else if (output_fire) begin
            if (rd_index == FRAME_LEN-1) begin
                rd_index <= 0;
                state <= S_CAPTURE;
            end else begin
                rd_index <= rd_index + 1'b1;
            end
        end
    end
endmodule
