`timescale 1ns/1ps
module tb_digital_delay_channel;
    reg clk = 0, rst = 1;
    reg s_valid = 0, s_last = 0;
    reg signed [15:0] s_i = 0, s_q = 0;
    reg m_ready = 1;
    wire s_ready, m_valid, m_last;
    wire signed [15:0] m_i, m_q;
    integer sent = 0, received = 0, expected, cycle = 0;

    always #4 clk = ~clk;
    digital_delay_channel_axis #(.FRAME_LEN(80), .DELAY(5)) dut (
        .clk(clk), .rst(rst),
        .s_axis_tvalid(s_valid), .s_axis_tready(s_ready),
        .s_axis_tlast(s_last), .s_axis_i(s_i), .s_axis_q(s_q),
        .m_axis_tready(m_ready), .m_axis_tvalid(m_valid),
        .m_axis_tlast(m_last), .m_axis_i(m_i), .m_axis_q(m_q)
    );

    always @(posedge clk) begin
        cycle = cycle + 1;
        m_ready <= (cycle % 13) != 0;
        if (m_valid && m_ready) begin
            expected = received < 5 ? 0 : received - 5;
            if (m_i !== expected || m_q !== -expected)
                $fatal(1, "delay mismatch at %0d: got (%0d,%0d), expected (%0d,%0d)",
                       received, m_i, m_q, expected, -expected);
            if (m_last !== (received == 79))
                $fatal(1, "output TLAST mismatch at %0d", received);
            received = received + 1;
            if (received == 80) begin
                $display("PASS digital delay channel: 5-sample delay, TLAST and stalls verified");
                $finish;
            end
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        @(negedge clk); rst = 0;
        while (sent < 80) begin
            @(negedge clk);
            s_valid = 1;
            s_last = (sent == 79);
            s_i = sent;
            s_q = -sent;
            @(posedge clk);
            if (s_ready) sent = sent + 1;
        end
        @(negedge clk); s_valid = 0; s_last = 0;
    end

    initial begin
        #20000;
        $fatal(1, "digital delay test timed out");
    end
endmodule
