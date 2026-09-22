`timescale 1ns/1ps
module tb_cp_insert_axis;
    reg clk = 1'b0, rst = 1'b1;
    reg s_valid = 1'b0;
    reg signed [15:0] s_i = 0, s_q = 0;
    reg m_ready = 1'b0;
    wire s_ready, m_valid, m_last;
    wire signed [15:0] m_i, m_q;
    integer k, out_count, expected, cycle_count;
    always #5 clk = ~clk;

    cp_insert_axis dut (
        .clk(clk), .rst(rst), .s_axis_tvalid(s_valid), .s_axis_tready(s_ready),
        .s_axis_i(s_i), .s_axis_q(s_q), .m_axis_tready(m_ready),
        .m_axis_tvalid(m_valid), .m_axis_tlast(m_last), .m_axis_i(m_i), .m_axis_q(m_q)
    );

    initial begin
        repeat (2) @(posedge clk); rst <= 1'b0;
        // Source holds valid until each sample is accepted.
        for (k = 0; k < 64; k = k + 1) begin
            @(negedge clk); s_valid <= 1'b1; s_i <= k; s_q <= -k;
            while (!s_ready) @(negedge clk);
            @(posedge clk);
        end
        @(negedge clk); s_valid <= 1'b0;
        out_count = 0;
        cycle_count = 0;
        // Deliberately pause the sink on every third cycle.
        while (out_count < 80) begin
            @(negedge clk); m_ready = ((cycle_count % 3) != 1); cycle_count = cycle_count + 1;
            if (m_valid && m_ready) begin
                if (out_count < 16) expected = 48 + out_count;
                else expected = out_count - 16;
                if (m_i !== expected || m_q !== -expected)
                    $fatal(1, "AXIS CP mismatch at %0d: got (%0d,%0d), expected (%0d,%0d)", out_count, m_i, m_q, expected, -expected);
                if ((out_count == 79) && !m_last)
                    $fatal(1, "m_axis_tlast missing on final transfer");
                out_count = out_count + 1;
            end
            @(posedge clk);
        end
        $display("PASS cp_insert_axis: valid/ready stalls preserved all 80 samples");
        $finish;
    end
endmodule
