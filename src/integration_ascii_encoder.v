`timescale 1ns / 1ps

// Integration-safe response encoder. The teammate ascii_encoder is preserved
// unchanged; this module fixes the formatter's mixed-width decimal arithmetic,
// which can place 8'h00 at the head of a valid numeric response and therefore
// terminate transmission before the first byte reaches the TX FIFO.
module integration_ascii_encoder (
    input        clk,
    input        reset,
    input        i_start,
    input  [2:0] i_source,
    input  [8:0] i_data0,
    input  [6:0] i_data1,
    input  [6:0] i_data2,
    input  [6:0] i_data3,
    input        i_fifo_full,
    output       o_fifo_push,
    output [7:0] o_data,
    output       o_encoder_free
);
    localparam IDLE = 1'b0;
    localparam SEND = 1'b1;

    localparam [2:0] RESP_SW    = 3'd2;
    localparam [2:0] RESP_WATCH = 3'd3;
    localparam [2:0] RESP_DIST  = 3'd4;
    localparam [2:0] RESP_DHT11 = 3'd5;

    reg state_reg;
    reg [239:0] buffer_reg;
    reg [239:0] formatted_data;

    function [7:0] decimal_digit;
        input [8:0] value;
        input integer divisor;
        begin
            decimal_digit = 8'h30 + ((value / divisor) % 10);
        end
    endfunction

    always @(*) begin
        formatted_data = 240'd0;
        case (i_source)
            RESP_SW: begin
                formatted_data = {
                    "(STOPWATCH): ",
                    decimal_digit(i_data0, 10), decimal_digit(i_data0, 1), ":",
                    decimal_digit({2'b00, i_data1}, 10), decimal_digit({2'b00, i_data1}, 1), ":",
                    decimal_digit({2'b00, i_data2}, 10), decimal_digit({2'b00, i_data2}, 1), ":",
                    decimal_digit({2'b00, i_data3}, 10), decimal_digit({2'b00, i_data3}, 1),
                    8'h0A, {5{8'h00}}
                };
            end
            RESP_WATCH: begin
                formatted_data = {
                    "(WATCH): ",
                    decimal_digit(i_data0, 10), decimal_digit(i_data0, 1), ":",
                    decimal_digit({2'b00, i_data1}, 10), decimal_digit({2'b00, i_data1}, 1), ":",
                    decimal_digit({2'b00, i_data2}, 10), decimal_digit({2'b00, i_data2}, 1), ":",
                    decimal_digit({2'b00, i_data3}, 10), decimal_digit({2'b00, i_data3}, 1),
                    8'h0A, {9{8'h00}}
                };
            end
            RESP_DIST: begin
                formatted_data = {
                    decimal_digit(i_data0, 100),
                    decimal_digit(i_data0, 10),
                    decimal_digit(i_data0, 1),
                    "cm", 8'h0A, {24{8'h00}}
                };
            end
            RESP_DHT11: begin
                formatted_data = {
                    decimal_digit({2'b00, i_data0[6:0]}, 10), decimal_digit({2'b00, i_data0[6:0]}, 1), ".",
                    decimal_digit({2'b00, i_data1}, 10), decimal_digit({2'b00, i_data1}, 1), "'C ",
                    decimal_digit({2'b00, i_data2}, 10), decimal_digit({2'b00, i_data2}, 1), ".",
                    decimal_digit({2'b00, i_data3}, 10), decimal_digit({2'b00, i_data3}, 1), "%",
                    8'h0A, {15{8'h00}}
                };
            end
            default: formatted_data = 240'd0;
        endcase
    end

    assign o_encoder_free = (state_reg == IDLE);
    assign o_fifo_push = (state_reg == SEND) && !i_fifo_full &&
                         (buffer_reg[239:232] != 8'h00);
    assign o_data = buffer_reg[239:232];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg  <= IDLE;
            buffer_reg <= 240'd0;
        end else begin
            case (state_reg)
                IDLE: begin
                    if (i_start) begin
                        buffer_reg <= formatted_data;
                        state_reg  <= SEND;
                    end
                end
                SEND: begin
                    if (!i_fifo_full) begin
                        if (buffer_reg[239:232] == 8'h00)
                            state_reg <= IDLE;
                        else
                            buffer_reg <= {buffer_reg[231:0], 8'h00};
                    end
                end
            endcase
        end
    end
endmodule
