`timescale 1ns/1ps
module tb_cp_insert;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg in_valid = 1'b0;
    reg signed [15:0] in_i = 16'sd0;
    reg signed [15:0] in_q = 16'sd0;
    wire in_ready;
    wire out_valid;
    wire signed [15:0] out_i;
    wire signed [15:0] out_q;
    wire frame_done;
    integer k;
    integer out_count;
    integer expected;

    always #5 clk = ~clk;

    cp_insert dut (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_ready(in_ready),
        .in_i(in_i), .in_q(in_q), .out_valid(out_valid),
        .out_i(out_i), .out_q(out_q), .frame_done(frame_done)
    );

    initial begin
        repeat (2) @(posedge clk);
        rst <= 1'b0;
        // Capture one deterministic complex OFDM useful symbol.
        for (k = 0; k < 64; k = k + 1) begin
            @(negedge clk);
            in_valid <= 1'b1;
            in_i <= k;
            in_q <= -k;
        end
        @(negedge clk);
        in_valid <= 1'b0;

        out_count = 0;
        while (out_count < 80) begin
            @(posedge clk);
            if (out_valid) begin
                if (out_count < 16)
                    expected = 48 + out_count;
                else
                    expected = out_count - 16;
                if (out_i !== expected || out_q !== -expected)
                    $fatal(1, "CP mismatch at %0d: got (%0d,%0d), expected (%0d,%0d)",
                           out_count, out_i, out_q, expected, -expected);
                out_count = out_count + 1;
            end
        end
        if (!frame_done) $fatal(1, "frame_done was not asserted on final sample");
        $display("PASS cp_insert: 16-sample prefix plus 64-sample symbol matched");
        $finish;
    end
endmodule
