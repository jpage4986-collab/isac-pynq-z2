`timescale 1ns/1ps

module tb_slow_sensing;
    reg clk = 0;
    reg rst = 1;
    reg s_valid = 0;
    reg s_last = 0;
    reg signed [15:0] s_i = 0, s_q = 0;
    reg sample_tick = 0;
    wire gate_valid;
    wire signed [15:0] gate_i, gate_q;
    wire slow_valid;
    wire signed [15:0] slow_i, slow_q;
    wire [31:0] sample_count;
    wire product_valid;
    wire signed [32:0] product_i, product_q;
    reg product_seen = 0;
    integer bin;

    always #4 clk = ~clk;
    always @(posedge clk) begin
        if (product_valid) begin
            product_seen <= 1'b1;
            if (product_i !== 33'sd0 || product_q !== -33'sd1000000)
                $fatal(1, "conjugate product mismatch: %0d, %0d", product_i, product_q);
        end
    end

    range_gate_sampler u_gate (
        .clk(clk), .rst(rst), .s_valid(s_valid), .s_last(s_last),
        .s_i(s_i), .s_q(s_q), .gate_valid(gate_valid),
        .gate_i(gate_i), .gate_q(gate_q)
    );
    slow_time_sampler u_sampler (
        .clk(clk), .rst(rst), .sample_tick(sample_tick),
        .gate_valid(gate_valid), .gate_i(gate_i), .gate_q(gate_q),
        .slow_valid(slow_valid), .slow_i(slow_i), .slow_q(slow_q),
        .sample_count(sample_count)
    );
    slow_phase_product u_phase (
        .clk(clk), .rst(rst), .slow_valid(slow_valid),
        .slow_i(slow_i), .slow_q(slow_q),
        .product_valid(product_valid), .product_i(product_i),
        .product_q(product_q)
    );

    task send_profile;
        input signed [15:0] target_i;
        input signed [15:0] target_q;
        begin
            for (bin = 0; bin < 64; bin = bin + 1) begin
                @(negedge clk);
                s_valid = 1;
                s_last = (bin == 63);
                s_i = (bin == 5) ? target_i : 16'sd0;
                s_q = (bin == 5) ? target_q : 16'sd0;
            end
            @(negedge clk);
            s_valid = 0;
            s_last = 0;
        end
    endtask

    task take_sample;
        begin
            @(negedge clk) sample_tick = 1;
            @(negedge clk) sample_tick = 0;
            @(negedge clk);
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 0;
        send_profile(16'sd1000, 16'sd0);
        if (!gate_valid || gate_i !== 16'sd1000 || gate_q !== 16'sd0)
            $fatal(1, "first target gate capture failed");
        take_sample();
        send_profile(16'sd0, -16'sd1000);
        take_sample();
        repeat (2) @(negedge clk);
        if (sample_count !== 2)
            $fatal(1, "expected two slow-time samples");
        if (!product_seen)
            $fatal(1, "conjugate product was never produced");
        $display("PASS slow sensing: gate=5 samples=2 product=(%0d,%0d)", product_i, product_q);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "slow sensing test timed out");
    end
endmodule
