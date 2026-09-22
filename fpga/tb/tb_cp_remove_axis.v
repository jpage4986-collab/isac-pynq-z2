`timescale 1ns/1ps
module tb_cp_remove_axis;
    reg clk = 1'b0, rst = 1'b1;
    reg s_valid = 1'b0;
    reg signed [15:0] s_i = 0, s_q = 0;
    reg m_ready = 1'b0;
    wire s_ready, m_valid, m_last;
    wire signed [15:0] m_i, m_q;
    integer k, out_count, cycle_count, expected;
    reg last_seen = 1'b0;
    always #5 clk = ~clk;

    cp_remove_axis dut (
        .clk(clk), .rst(rst), .s_axis_tvalid(s_valid), .s_axis_tready(s_ready),
        .s_axis_i(s_i), .s_axis_q(s_q), .m_axis_tready(m_ready),
        .m_axis_tvalid(m_valid), .m_axis_tlast(m_last), .m_axis_i(m_i), .m_axis_q(m_q)
    );

    // Check output before each rising edge, when a valid/ready transfer occurs.
    always @(negedge clk) begin
        cycle_count = cycle_count + 1;
        m_ready = ((cycle_count % 3) != 1);
        if (m_valid && m_ready) begin
            expected = out_count;
            if (m_i !== expected || m_q !== -expected)
                $fatal(1, "AXIS CP removal mismatch at %0d", out_count);
            if (out_count == 63) begin
                if (!m_last) $fatal(1, "m_axis_tlast missing on final output");
                last_seen = 1'b1;
            end
            out_count = out_count + 1;
        end
    end

    initial begin
        out_count = 0; cycle_count = 0;
        repeat (2) @(posedge clk); rst <= 1'b0;
        for (k = 0; k < 80; k = k + 1) begin
            @(negedge clk);
            s_valid = 1'b1;
            if (k < 16) begin s_i = 48 + k; s_q = -(48 + k); end
            else begin s_i = k - 16; s_q = -(k - 16); end
            while (!s_ready) @(negedge clk);
            @(posedge clk);
        end
        @(negedge clk); s_valid = 1'b0;
        wait (out_count == 64);
        #1;
        if (!last_seen) $fatal(1, "AXIS CP removal did not produce final last");
        $display("PASS cp_remove_axis: valid/ready stalls recovered all 64 samples");
        $finish;
    end
endmodule
