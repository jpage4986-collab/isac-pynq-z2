`timescale 1ns/1ps

// Removes the deterministic exp(-j*2*pi*k*5/64) phase ramp produced by the
// 5-sample digital target. It is the communication-side equalizer for the
// same received FFT frames that feed the sensing H=Y/X branch.
module delay5_equalizer_axis (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire s_axis_tlast,
    input  wire signed [15:0] s_axis_i,
    input  wire signed [15:0] s_axis_q,
    input  wire m_axis_tready,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    output wire signed [15:0] m_axis_i,
    output wire signed [15:0] m_axis_q
);
    reg [5:0] bin_index;
    reg stage1_valid, stage1_last;
    reg signed [15:0] stage1_i, stage1_q, stage1_cos, stage1_sin;
    reg stage2_valid, stage2_last;
    reg signed [31:0] stage2_ic, stage2_qs, stage2_is, stage2_qc;
    reg stage3_valid, stage3_last;
    reg signed [15:0] stage3_i, stage3_q;
    wire ready3 = !stage3_valid || m_axis_tready;
    wire ready2 = !stage2_valid || ready3;
    wire ready1 = !stage1_valid || ready2;

    function signed [15:0] coeff_cos_lut;
        input [5:0] index;
        begin
            case (index)
                6'd0: coeff_cos_lut = 16'sd16384; 6'd1: coeff_cos_lut = 16'sd14449;
                6'd2: coeff_cos_lut = 16'sd9102; 6'd3: coeff_cos_lut = 16'sd1606;
                6'd4: coeff_cos_lut = -16'sd6270; 6'd5: coeff_cos_lut = -16'sd12665;
                6'd6: coeff_cos_lut = -16'sd16069; 6'd7: coeff_cos_lut = -16'sd15679;
                6'd8: coeff_cos_lut = -16'sd11585; 6'd9: coeff_cos_lut = -16'sd4756;
                6'd10: coeff_cos_lut = 16'sd3196; 6'd11: coeff_cos_lut = 16'sd10394;
                6'd12: coeff_cos_lut = 16'sd15137; 6'd13: coeff_cos_lut = 16'sd16305;
                6'd14: coeff_cos_lut = 16'sd13623; 6'd15: coeff_cos_lut = 16'sd7723;
                6'd16: coeff_cos_lut = 16'sd0; 6'd17: coeff_cos_lut = -16'sd7723;
                6'd18: coeff_cos_lut = -16'sd13623; 6'd19: coeff_cos_lut = -16'sd16305;
                6'd20: coeff_cos_lut = -16'sd15137; 6'd21: coeff_cos_lut = -16'sd10394;
                6'd22: coeff_cos_lut = -16'sd3196; 6'd23: coeff_cos_lut = 16'sd4756;
                6'd24: coeff_cos_lut = 16'sd11585; 6'd25: coeff_cos_lut = 16'sd15679;
                6'd26: coeff_cos_lut = 16'sd16069; 6'd27: coeff_cos_lut = 16'sd12665;
                6'd28: coeff_cos_lut = 16'sd6270; 6'd29: coeff_cos_lut = -16'sd1606;
                6'd30: coeff_cos_lut = -16'sd9102; 6'd31: coeff_cos_lut = -16'sd14449;
                6'd32: coeff_cos_lut = -16'sd16384; 6'd33: coeff_cos_lut = -16'sd14449;
                6'd34: coeff_cos_lut = -16'sd9102; 6'd35: coeff_cos_lut = -16'sd1606;
                6'd36: coeff_cos_lut = 16'sd6270; 6'd37: coeff_cos_lut = 16'sd12665;
                6'd38: coeff_cos_lut = 16'sd16069; 6'd39: coeff_cos_lut = 16'sd15679;
                6'd40: coeff_cos_lut = 16'sd11585; 6'd41: coeff_cos_lut = 16'sd4756;
                6'd42: coeff_cos_lut = -16'sd3196; 6'd43: coeff_cos_lut = -16'sd10394;
                6'd44: coeff_cos_lut = -16'sd15137; 6'd45: coeff_cos_lut = -16'sd16305;
                6'd46: coeff_cos_lut = -16'sd13623; 6'd47: coeff_cos_lut = -16'sd7723;
                6'd48: coeff_cos_lut = 16'sd0; 6'd49: coeff_cos_lut = 16'sd7723;
                6'd50: coeff_cos_lut = 16'sd13623; 6'd51: coeff_cos_lut = 16'sd16305;
                6'd52: coeff_cos_lut = 16'sd15137; 6'd53: coeff_cos_lut = 16'sd10394;
                6'd54: coeff_cos_lut = 16'sd3196; 6'd55: coeff_cos_lut = -16'sd4756;
                6'd56: coeff_cos_lut = -16'sd11585; 6'd57: coeff_cos_lut = -16'sd15679;
                6'd58: coeff_cos_lut = -16'sd16069; 6'd59: coeff_cos_lut = -16'sd12665;
                6'd60: coeff_cos_lut = -16'sd6270; 6'd61: coeff_cos_lut = 16'sd1606;
                6'd62: coeff_cos_lut = 16'sd9102; default: coeff_cos_lut = 16'sd14449;
            endcase
        end
    endfunction

    function signed [15:0] coeff_sin_lut;
        input [5:0] index;
        begin
            case (index)
                6'd0: coeff_sin_lut = 16'sd0; 6'd1: coeff_sin_lut = 16'sd7723;
                6'd2: coeff_sin_lut = 16'sd13623; 6'd3: coeff_sin_lut = 16'sd16305;
                6'd4: coeff_sin_lut = 16'sd15137; 6'd5: coeff_sin_lut = 16'sd10394;
                6'd6: coeff_sin_lut = 16'sd3196; 6'd7: coeff_sin_lut = -16'sd4756;
                6'd8: coeff_sin_lut = -16'sd11585; 6'd9: coeff_sin_lut = -16'sd15679;
                6'd10: coeff_sin_lut = -16'sd16069; 6'd11: coeff_sin_lut = -16'sd12665;
                6'd12: coeff_sin_lut = -16'sd6270; 6'd13: coeff_sin_lut = 16'sd1606;
                6'd14: coeff_sin_lut = 16'sd9102; 6'd15: coeff_sin_lut = 16'sd14449;
                6'd16: coeff_sin_lut = 16'sd16384; 6'd17: coeff_sin_lut = 16'sd14449;
                6'd18: coeff_sin_lut = 16'sd9102; 6'd19: coeff_sin_lut = 16'sd1606;
                6'd20: coeff_sin_lut = -16'sd6270; 6'd21: coeff_sin_lut = -16'sd12665;
                6'd22: coeff_sin_lut = -16'sd16069; 6'd23: coeff_sin_lut = -16'sd15679;
                6'd24: coeff_sin_lut = -16'sd11585; 6'd25: coeff_sin_lut = -16'sd4756;
                6'd26: coeff_sin_lut = 16'sd3196; 6'd27: coeff_sin_lut = 16'sd10394;
                6'd28: coeff_sin_lut = 16'sd15137; 6'd29: coeff_sin_lut = 16'sd16305;
                6'd30: coeff_sin_lut = 16'sd13623; 6'd31: coeff_sin_lut = 16'sd7723;
                6'd32: coeff_sin_lut = 16'sd0; 6'd33: coeff_sin_lut = -16'sd7723;
                6'd34: coeff_sin_lut = -16'sd13623; 6'd35: coeff_sin_lut = -16'sd16305;
                6'd36: coeff_sin_lut = -16'sd15137; 6'd37: coeff_sin_lut = -16'sd10394;
                6'd38: coeff_sin_lut = -16'sd3196; 6'd39: coeff_sin_lut = 16'sd4756;
                6'd40: coeff_sin_lut = 16'sd11585; 6'd41: coeff_sin_lut = 16'sd15679;
                6'd42: coeff_sin_lut = 16'sd16069; 6'd43: coeff_sin_lut = 16'sd12665;
                6'd44: coeff_sin_lut = 16'sd6270; 6'd45: coeff_sin_lut = -16'sd1606;
                6'd46: coeff_sin_lut = -16'sd9102; 6'd47: coeff_sin_lut = -16'sd14449;
                6'd48: coeff_sin_lut = -16'sd16384; 6'd49: coeff_sin_lut = -16'sd14449;
                6'd50: coeff_sin_lut = -16'sd9102; 6'd51: coeff_sin_lut = -16'sd1606;
                6'd52: coeff_sin_lut = 16'sd6270; 6'd53: coeff_sin_lut = 16'sd12665;
                6'd54: coeff_sin_lut = 16'sd16069; 6'd55: coeff_sin_lut = 16'sd15679;
                6'd56: coeff_sin_lut = 16'sd11585; 6'd57: coeff_sin_lut = 16'sd4756;
                6'd58: coeff_sin_lut = -16'sd3196; 6'd59: coeff_sin_lut = -16'sd10394;
                6'd60: coeff_sin_lut = -16'sd15137; 6'd61: coeff_sin_lut = -16'sd16305;
                6'd62: coeff_sin_lut = -16'sd13623; default: coeff_sin_lut = -16'sd7723;
            endcase
        end
    endfunction

    assign s_axis_tready = ready1;
    assign m_axis_tvalid = stage3_valid;
    assign m_axis_tlast = stage3_last;
    assign m_axis_i = stage3_i;
    assign m_axis_q = stage3_q;

    always @(posedge clk) begin
        if (rst) begin
            bin_index <= 0;
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            stage3_valid <= 1'b0;
            stage1_last <= 1'b0;
            stage2_last <= 1'b0;
            stage3_last <= 1'b0;
            stage1_i <= 0;
            stage1_q <= 0;
            stage1_cos <= 0;
            stage1_sin <= 0;
            stage2_ic <= 0;
            stage2_qs <= 0;
            stage2_is <= 0;
            stage2_qc <= 0;
            stage3_i <= 0;
            stage3_q <= 0;
        end else begin
            if (ready3) begin
                stage3_valid <= stage2_valid;
                stage3_last <= stage2_last;
                if (stage2_valid) begin
                    stage3_i <= ({stage2_ic[31], stage2_ic} - {stage2_qs[31], stage2_qs}) >>> 14;
                    stage3_q <= ({stage2_is[31], stage2_is} + {stage2_qc[31], stage2_qc}) >>> 14;
                end
            end
            if (ready2) begin
                stage2_valid <= stage1_valid;
                stage2_last <= stage1_last;
                if (stage1_valid) begin
                    stage2_ic <= $signed(stage1_i) * $signed(stage1_cos);
                    stage2_qs <= $signed(stage1_q) * $signed(stage1_sin);
                    stage2_is <= $signed(stage1_i) * $signed(stage1_sin);
                    stage2_qc <= $signed(stage1_q) * $signed(stage1_cos);
                end
            end
            if (ready1) begin
                stage1_valid <= s_axis_tvalid;
                stage1_last <= s_axis_tlast;
                if (s_axis_tvalid) begin
                    stage1_i <= s_axis_i;
                    stage1_q <= s_axis_q;
                    stage1_cos <= coeff_cos_lut(bin_index);
                    stage1_sin <= coeff_sin_lut(bin_index);
                    if (s_axis_tlast)
                        bin_index <= 0;
                    else
                        bin_index <= bin_index + 1'b1;
                end
            end
        end
    end
endmodule
