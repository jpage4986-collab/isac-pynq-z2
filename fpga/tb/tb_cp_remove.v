`timescale 1ns/1ps
module tb_cp_remove;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg in_valid = 1'b0;
    reg signed [15:0] in_i = 16'sd0;
    reg signed [15:0] in_q = 16'sd0;
    wire in_ready, out_valid, frame_done;
    wire signed [15:0] out_i, out_q;
    integer k, out_count;

    always #5 clk = ~clk;
    cp_remove dut (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_ready(in_ready),
        .in_i(in_i), .in_q(in_q), .out_valid(out_valid),
        .out_i(out_i), .out_q(out_q), .frame_done(frame_done)
    );

    initial begin
        repeat (2) @(posedge clk);
        rst <= 1'b0;
        // Feed the expected CP-extended frame: 48..63, then 0..63.
        for (k = 0; k < 80; k = k + 1) begin
            @(negedge clk);
            in_valid <= 1'b1;
            if (k < 16) begin in_i <= 48 + k; in_q <= -(48 + k); end
            else begin in_i <= k - 16; in_q <= -(k - 16); end
            @(posedge clk);
            #1;
            if (out_valid) begin
                if (out_i !== (k - 16) || out_q !== -(k - 16))
                    $fatal(1, "CP removal mismatch at input %0d", k);
            end
        end
        @(negedge clk); in_valid <= 1'b0;
        #1;
        if (!frame_done) $fatal(1, "frame_done was not asserted");
        $display("PASS cp_remove: discarded 16-sample prefix and recovered 64 samples");
        $finish;
    end
endmodule
