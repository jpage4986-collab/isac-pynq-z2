`timescale 1ns/1ps

// 100 Hz digital structural-vibration phasor for a 500 um round-trip
// displacement at 5.8 GHz. No RF hardware is implied. The Q14 table is
// exp(-j*4*pi*displacement/lambda) for 64 NCO phase locations.
// PHASE_STEP=103079215 produces approximately 2.4 Hz at 100 Hz sampling;
// PHASE_STEP=88046830 produces approximately 2.05 Hz.
module vibration_phasor_q14 #(
    parameter integer SLOW_DIV = 1250000,
    parameter [31:0] PHASE_STEP = 32'd103079215
) (
    input wire clk,
    input wire rst,
    input wire frame_boundary,
    output reg sample_tick,
    output reg signed [15:0] cos_q14,
    output reg signed [15:0] sin_q14
);
    reg [31:0] slow_counter;
    reg pending;
    reg [31:0] phase_accumulator;
    wire [5:0] lut_index = phase_accumulator[31:26];

    initial begin
        if (SLOW_DIV < 2)
            $error("SLOW_DIV must be at least 2");
    end

    always @* begin
        case (lut_index)
            6'd0: begin cos_q14 = 16'sd16384; sin_q14 = 16'sd0; end
            6'd1: begin cos_q14 = 16'sd16383; sin_q14 = -16'sd195; end
            6'd2: begin cos_q14 = 16'sd16379; sin_q14 = -16'sd389; end
            6'd3: begin cos_q14 = 16'sd16374; sin_q14 = -16'sd578; end
            6'd4: begin cos_q14 = 16'sd16366; sin_q14 = -16'sd762; end
            6'd5: begin cos_q14 = 16'sd16357; sin_q14 = -16'sd938; end
            6'd6: begin cos_q14 = 16'sd16347; sin_q14 = -16'sd1106; end
            6'd7: begin cos_q14 = 16'sd16335; sin_q14 = -16'sd1262; end
            6'd8: begin cos_q14 = 16'sd16324; sin_q14 = -16'sd1407; end
            6'd9: begin cos_q14 = 16'sd16312; sin_q14 = -16'sd1537; end
            6'd10: begin cos_q14 = 16'sd16300; sin_q14 = -16'sd1653; end
            6'd11: begin cos_q14 = 16'sd16290; sin_q14 = -16'sd1753; end
            6'd12: begin cos_q14 = 16'sd16281; sin_q14 = -16'sd1836; end
            6'd13: begin cos_q14 = 16'sd16273; sin_q14 = -16'sd1902; end
            6'd14: begin cos_q14 = 16'sd16268; sin_q14 = -16'sd1949; end
            6'd15: begin cos_q14 = 16'sd16264; sin_q14 = -16'sd1977; end
            6'd16: begin cos_q14 = 16'sd16263; sin_q14 = -16'sd1987; end
            6'd17: begin cos_q14 = 16'sd16264; sin_q14 = -16'sd1977; end
            6'd18: begin cos_q14 = 16'sd16268; sin_q14 = -16'sd1949; end
            6'd19: begin cos_q14 = 16'sd16273; sin_q14 = -16'sd1902; end
            6'd20: begin cos_q14 = 16'sd16281; sin_q14 = -16'sd1836; end
            6'd21: begin cos_q14 = 16'sd16290; sin_q14 = -16'sd1753; end
            6'd22: begin cos_q14 = 16'sd16300; sin_q14 = -16'sd1653; end
            6'd23: begin cos_q14 = 16'sd16312; sin_q14 = -16'sd1537; end
            6'd24: begin cos_q14 = 16'sd16324; sin_q14 = -16'sd1407; end
            6'd25: begin cos_q14 = 16'sd16335; sin_q14 = -16'sd1262; end
            6'd26: begin cos_q14 = 16'sd16347; sin_q14 = -16'sd1106; end
            6'd27: begin cos_q14 = 16'sd16357; sin_q14 = -16'sd938; end
            6'd28: begin cos_q14 = 16'sd16366; sin_q14 = -16'sd762; end
            6'd29: begin cos_q14 = 16'sd16374; sin_q14 = -16'sd578; end
            6'd30: begin cos_q14 = 16'sd16379; sin_q14 = -16'sd389; end
            6'd31: begin cos_q14 = 16'sd16383; sin_q14 = -16'sd195; end
            6'd32: begin cos_q14 = 16'sd16384; sin_q14 = 16'sd0; end
            6'd33: begin cos_q14 = 16'sd16383; sin_q14 = 16'sd195; end
            6'd34: begin cos_q14 = 16'sd16379; sin_q14 = 16'sd389; end
            6'd35: begin cos_q14 = 16'sd16374; sin_q14 = 16'sd578; end
            6'd36: begin cos_q14 = 16'sd16366; sin_q14 = 16'sd762; end
            6'd37: begin cos_q14 = 16'sd16357; sin_q14 = 16'sd938; end
            6'd38: begin cos_q14 = 16'sd16347; sin_q14 = 16'sd1106; end
            6'd39: begin cos_q14 = 16'sd16335; sin_q14 = 16'sd1262; end
            6'd40: begin cos_q14 = 16'sd16324; sin_q14 = 16'sd1407; end
            6'd41: begin cos_q14 = 16'sd16312; sin_q14 = 16'sd1537; end
            6'd42: begin cos_q14 = 16'sd16300; sin_q14 = 16'sd1653; end
            6'd43: begin cos_q14 = 16'sd16290; sin_q14 = 16'sd1753; end
            6'd44: begin cos_q14 = 16'sd16281; sin_q14 = 16'sd1836; end
            6'd45: begin cos_q14 = 16'sd16273; sin_q14 = 16'sd1902; end
            6'd46: begin cos_q14 = 16'sd16268; sin_q14 = 16'sd1949; end
            6'd47: begin cos_q14 = 16'sd16264; sin_q14 = 16'sd1977; end
            6'd48: begin cos_q14 = 16'sd16263; sin_q14 = 16'sd1987; end
            6'd49: begin cos_q14 = 16'sd16264; sin_q14 = 16'sd1977; end
            6'd50: begin cos_q14 = 16'sd16268; sin_q14 = 16'sd1949; end
            6'd51: begin cos_q14 = 16'sd16273; sin_q14 = 16'sd1902; end
            6'd52: begin cos_q14 = 16'sd16281; sin_q14 = 16'sd1836; end
            6'd53: begin cos_q14 = 16'sd16290; sin_q14 = 16'sd1753; end
            6'd54: begin cos_q14 = 16'sd16300; sin_q14 = 16'sd1653; end
            6'd55: begin cos_q14 = 16'sd16312; sin_q14 = 16'sd1537; end
            6'd56: begin cos_q14 = 16'sd16324; sin_q14 = 16'sd1407; end
            6'd57: begin cos_q14 = 16'sd16335; sin_q14 = 16'sd1262; end
            6'd58: begin cos_q14 = 16'sd16347; sin_q14 = 16'sd1106; end
            6'd59: begin cos_q14 = 16'sd16357; sin_q14 = 16'sd938; end
            6'd60: begin cos_q14 = 16'sd16366; sin_q14 = 16'sd762; end
            6'd61: begin cos_q14 = 16'sd16374; sin_q14 = 16'sd578; end
            6'd62: begin cos_q14 = 16'sd16379; sin_q14 = 16'sd389; end
            6'd63: begin cos_q14 = 16'sd16383; sin_q14 = 16'sd195; end
            default: begin cos_q14 = 16'sd16384; sin_q14 = 16'sd0; end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            slow_counter <= 0;
            pending <= 1'b0;
            phase_accumulator <= 0;
            sample_tick <= 1'b0;
        end else begin
            sample_tick <= 1'b0;
            if (slow_counter == SLOW_DIV-1) begin
                slow_counter <= 0;
                pending <= 1'b1;
            end else begin
                slow_counter <= slow_counter + 1'b1;
            end
            // Commit the new phasor only after the channel's final OFDM sample
            // has been accepted, so a frame cannot contain two target phases.
            if (pending && frame_boundary) begin
                phase_accumulator <= phase_accumulator + PHASE_STEP;
                // A new period may expire on this same clock. Keep that
                // request queued for the next frame instead of dropping it.
                pending <= (slow_counter == SLOW_DIV-1);
                sample_tick <= 1'b1;
            end
        end
    end
endmodule
