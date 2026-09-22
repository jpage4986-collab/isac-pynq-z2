`timescale 1ns/1ps
module tb_qpsk_mapper;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg in_valid = 1'b0;
    reg [1:0] bits = 2'b00;
    wire out_valid;
    wire signed [15:0] i_out;
    wire signed [15:0] q_out;

    qpsk_mapper dut (
        .clk(clk), .rst(rst), .in_valid(in_valid), .bits(bits),
        .out_valid(out_valid), .i_out(i_out), .q_out(q_out)
    );

    always #5 clk = ~clk;

    task automatic send_and_check(input [1:0] b, input integer expected_i, input integer expected_q);
        begin
            @(negedge clk);
            bits = b;
            in_valid = 1'b1;
            @(negedge clk);
            in_valid = 1'b0;
            #1;
            if (!out_valid || i_out !== expected_i || q_out !== expected_q) begin
                $display("FAIL bits=%b valid=%b i=%0d q=%0d", b, out_valid, i_out, q_out);
                $fatal(1);
            end
        end
    endtask

    initial begin
        #12;
        @(negedge clk);
        rst = 1'b0;
        send_and_check(2'b00,  23170,  23170);
        send_and_check(2'b01,  23170, -23170);
        send_and_check(2'b10, -23170,  23170);
        send_and_check(2'b11, -23170, -23170);
        $display("PASS qpsk_mapper: all four QPSK points matched Q1.15 reference");
        $finish;
    end
endmodule
