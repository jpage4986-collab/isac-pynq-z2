`timescale 1ns/1ps

module tb_vibration_phasor_q14;
    reg clk = 0;
    reg rst = 1;
    reg frame_boundary = 0;
    wire sample_tick;
    wire signed [15:0] cos_q14, sin_q14;
    integer tick_count = 0;

    always #4 clk = ~clk;

    vibration_phasor_q14 #(
        .SLOW_DIV(4), .PHASE_STEP(32'h40000000)
    ) dut (
        .clk(clk), .rst(rst), .frame_boundary(frame_boundary),
        .sample_tick(sample_tick), .cos_q14(cos_q14), .sin_q14(sin_q14)
    );

    initial begin
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 0;
        if (cos_q14 !== 16'sd16384 || sin_q14 !== 16'sd0)
            $fatal(1, "reset phasor is not unity");
        repeat (9) @(posedge clk);
        if (sample_tick !== 1'b0)
            $fatal(1, "phasor changed without a frame boundary");
        @(negedge clk) frame_boundary = 1;
        repeat (4) begin
            @(posedge sample_tick);
            @(negedge clk);
            tick_count = tick_count + 1;
            case (tick_count)
                1: if (cos_q14 !== 16'sd16263 || sin_q14 !== -16'sd1987)
                    $fatal(1, "quarter-cycle phasor mismatch: %0d, %0d", cos_q14, sin_q14);
                2: if (cos_q14 !== 16'sd16384 || sin_q14 !== 16'sd0)
                    $fatal(1, "half-cycle phasor mismatch");
                3: if (cos_q14 !== 16'sd16263 || sin_q14 !== 16'sd1987)
                    $fatal(1, "three-quarter-cycle phasor mismatch");
                4: if (cos_q14 !== 16'sd16384 || sin_q14 !== 16'sd0)
                    $fatal(1, "full-cycle phasor mismatch");
            endcase
        end
        $display("PASS vibration phasor: frame-aligned Q14 cycle");
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "vibration phasor test timed out");
    end
endmodule
