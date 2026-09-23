`timescale 1ns/1ps

module tb_isac_dynamic;
    reg clk = 0;
    reg btn0 = 1;
    wire led0, led1, led2, led3;
    reg nonzero_phase_product_seen = 0;

    always #4 clk = ~clk;

    isac_integrated_top #(
        .SLOW_DIV(1500), .PHASE_STEP(32'h40000000)
    ) dut (
        .clk(clk), .btn0(btn0), .led0(led0), .led1(led1),
        .led2(led2), .led3(led3)
    );

    always @(posedge clk) begin
        if (dut.phase_product_valid && dut.phase_product_q != 0)
            nonzero_phase_product_seen <= 1'b1;
    end

    initial begin
        repeat (5) @(posedge clk);
        @(negedge clk) btn0 = 0;
        wait (dut.slow_sample_count >= 5);
        repeat (10) @(posedge clk);
        if (!led1 || !led2 || led3)
            $fatal(1, "dynamic integrated status LEDs failed: %b%b%b", led1, led2, led3);
        if (dut.bit_errors !== 0 || dut.peak_bin !== 6'd5)
            $fatal(1, "dynamic integration lost communication or range");
        if (!nonzero_phase_product_seen)
            $fatal(1, "no changing target phase was observed");
        $display("PASS dynamic ISAC: slow_samples=%0d bits=%0d errors=%0d peak_bin=%0d",
                 dut.slow_sample_count, dut.bit_count, dut.bit_errors, dut.peak_bin);
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "dynamic ISAC test timed out");
    end
endmodule
