module led_blink #(
    parameter integer CLK_HZ  = 125_000_000,
    parameter integer BLINK_HZ = 1
) (
    input  wire clk,
    input  wire btn0,
    output reg  led0
);
    // One toggle per half-period gives one complete on/off blink per BLINK_HZ.
    localparam integer HALF_PERIOD = CLK_HZ / (2 * BLINK_HZ);
    localparam integer COUNT_WIDTH = (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);

    reg [COUNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (btn0) begin
            counter <= {COUNT_WIDTH{1'b0}};
            led0    <= 1'b0;
        end else if (counter == HALF_PERIOD - 1) begin
            counter <= {COUNT_WIDTH{1'b0}};
            led0    <= ~led0;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule
