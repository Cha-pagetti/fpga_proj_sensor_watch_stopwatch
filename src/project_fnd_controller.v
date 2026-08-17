`timescale 1ns / 1ps

// Four-digit seven-segment display driver for the integrated project.
module project_fnd_controller #(
    parameter integer CLK_FREQ_HZ = 100_000_000
) (
    input         clk,
    input         reset,
    input  [13:0] i_value,
    input  [ 3:0] i_decimal_mask,
    output reg [3:0] fnd_com,
    output reg [7:0] fnd_data
);
    localparam integer SCAN_DIV = CLK_FREQ_HZ / 4_000;
    localparam integer SCAN_WIDTH = (SCAN_DIV <= 1) ? 1 : $clog2(SCAN_DIV);

    reg [SCAN_WIDTH-1:0] scan_count_reg;
    reg [1:0] digit_select_reg;
    reg [3:0] selected_digit;

    wire [3:0] digit_ones;
    wire [3:0] digit_tens;
    wire [3:0] digit_hundreds;
    wire [3:0] digit_thousands;

    assign digit_ones     = i_value % 10;
    assign digit_tens     = (i_value / 10) % 10;
    assign digit_hundreds = (i_value / 100) % 10;
    assign digit_thousands = (i_value / 1000) % 10;

    function [7:0] seven_segment;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seven_segment = 8'hC0;
                4'd1: seven_segment = 8'hF9;
                4'd2: seven_segment = 8'hA4;
                4'd3: seven_segment = 8'hB0;
                4'd4: seven_segment = 8'h99;
                4'd5: seven_segment = 8'h92;
                4'd6: seven_segment = 8'h82;
                4'd7: seven_segment = 8'hF8;
                4'd8: seven_segment = 8'h80;
                4'd9: seven_segment = 8'h90;
                default: seven_segment = 8'hFF;
            endcase
        end
    endfunction

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            scan_count_reg   <= 0;
            digit_select_reg <= 0;
        end else if (SCAN_DIV <= 1 || scan_count_reg == SCAN_DIV - 1) begin
            scan_count_reg   <= 0;
            digit_select_reg <= digit_select_reg + 1'b1;
        end else begin
            scan_count_reg <= scan_count_reg + 1'b1;
        end
    end

    always @(*) begin
        case (digit_select_reg)
            2'd0: begin fnd_com = 4'b1110; selected_digit = digit_ones; end
            2'd1: begin fnd_com = 4'b1101; selected_digit = digit_tens; end
            2'd2: begin fnd_com = 4'b1011; selected_digit = digit_hundreds; end
            default: begin fnd_com = 4'b0111; selected_digit = digit_thousands; end
        endcase
        fnd_data = seven_segment(selected_digit);
        if (i_decimal_mask[digit_select_reg])
            fnd_data[7] = 1'b0;
    end
endmodule
