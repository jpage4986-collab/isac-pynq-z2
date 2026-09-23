`timescale 1ns/1ps

// Accelerate the 100 Hz divider while retaining the exact 2.4 Hz NCO step.
// One emitted line is one equivalent slow-time sample.
module tb_vibration_nco_4096;
    reg clk = 0;
    reg rst = 1;
    wire sample_tick;
    wire signed [15:0] cos_q14, sin_q14;
    integer file_handle;
    integer index;

    always #4 clk = ~clk;

    vibration_phasor_q14 #(.SLOW_DIV(4), .PHASE_STEP(32'd103079215)) dut (
        .clk(clk), .rst(rst), .frame_boundary(1'b1),
        .sample_tick(sample_tick), .cos_q14(cos_q14), .sin_q14(sin_q14)
    );

    initial begin
        file_handle = $fopen("vibration_nco_4096.csv", "w");
        if (file_handle == 0)
            $fatal(1, "cannot create NCO CSV");
        $fdisplay(file_handle, "sample,cos_q14,sin_q14");
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 0;
        for (index = 0; index < 4096; index = index + 1) begin
            @(posedge sample_tick);
            #1;
            $fdisplay(file_handle, "%0d,%0d,%0d", index, cos_q14, sin_q14);
        end
        $fclose(file_handle);
        $display("PASS vibration NCO: 4096 samples exported");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "4096-sample NCO test timed out");
    end
endmodule
