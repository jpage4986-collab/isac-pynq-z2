`timescale 1ns/1ps

module tb_isac_integrated;
    reg clk = 0;
    reg btn0 = 1;
    wire led0, led1, led2, led3;

    always #4 clk = ~clk;

    isac_integrated_top dut (
        .clk(clk), .btn0(btn0), .led0(led0), .led1(led1), .led2(led2), .led3(led3)
    );

    initial begin
        repeat (5) @(posedge clk);
        @(negedge clk) btn0 = 0;
        wait (led1 && led2);
        repeat (30) @(posedge clk);
        if (led3 !== 1'b0)
            $fatal(1, "integrated ISAC status reported an error");
        if (dut.bit_errors !== 0)
            $fatal(1, "communication errors: %0d", dut.bit_errors);
        if (dut.peak_bin !== 6'd5)
            $fatal(1, "range peak was %0d, expected 5", dut.peak_bin);
        $display("PASS integrated ISAC: bits=%0d errors=%0d peak_bin=%0d magnitude=%0d",
                 dut.bit_count, dut.bit_errors, dut.peak_bin, dut.peak_magnitude);
        $finish;
    end

    initial begin
        #500000;
        $fatal(1, "integrated ISAC test timed out");
    end
endmodule
