`timescale 1ns/1ps

// Broadcast every FFT frame to communication processing and only alternating
// known training frames to sensing. Both branches must accept a training
// sample before the upstream FFT advances, preserving one shared receive flow.
module ofdm_training_broadcaster (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire s_axis_tlast,
    input  wire signed [15:0] s_axis_i,
    input  wire signed [15:0] s_axis_q,
    input  wire comm_axis_tready,
    output wire comm_axis_tvalid,
    output wire comm_axis_tlast,
    output wire signed [15:0] comm_axis_i,
    output wire signed [15:0] comm_axis_q,
    input  wire training_axis_tready,
    output wire training_axis_tvalid,
    output wire training_axis_tlast,
    output wire signed [15:0] training_axis_i,
    output wire signed [15:0] training_axis_q
);
    reg training_frame;
    wire needs_training_ready = !training_frame || training_axis_tready;
    wire fire = s_axis_tvalid && s_axis_tready;

    assign s_axis_tready = comm_axis_tready && needs_training_ready;
    assign comm_axis_tvalid = s_axis_tvalid;
    assign comm_axis_tlast = s_axis_tlast;
    assign comm_axis_i = s_axis_i;
    assign comm_axis_q = s_axis_q;
    assign training_axis_tvalid = s_axis_tvalid && training_frame;
    assign training_axis_tlast = s_axis_tlast;
    assign training_axis_i = s_axis_i;
    assign training_axis_q = s_axis_q;

    always @(posedge clk) begin
        if (rst)
            training_frame <= 1'b1;
        else if (fire && s_axis_tlast)
            training_frame <= !training_frame;
    end
endmodule
