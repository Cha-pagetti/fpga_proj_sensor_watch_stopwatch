`timescale 1ns / 1ps

// Formats project responses and streams them into the UART TX FIFO.
module ascii_encoder (
    input        clk,
    input        reset,
    input        i_start,
    input  [2:0] i_kind,

    input  [6:0] i_sw_msec,
    input  [5:0] i_sw_sec,
    input  [5:0] i_sw_min,
    input  [4:0] i_sw_hour,

    input  [5:0] i_watch_sec,
    input  [5:0] i_watch_min,
    input  [4:0] i_watch_hour,

    input  [8:0] i_distance,
    input [15:0] i_temperature,
    input [15:0] i_humidity,

    input        i_tx_full,
    output reg [7:0] o_tx_data,
    output reg       o_tx_push,
    output reg       o_busy,
    output reg       o_done
);
    localparam [2:0] RESP_ACK   = 3'd0;
    localparam [2:0] RESP_ERROR = 3'd1;
    localparam [2:0] RESP_SW    = 3'd2;
    localparam [2:0] RESP_WATCH = 3'd3;
    localparam [2:0] RESP_DIST  = 3'd4;
    localparam [2:0] RESP_DHT11 = 3'd5;

    reg [7:0] message [0:23];
    reg [4:0] length_reg;
    reg [4:0] index_reg;

    function [7:0] ascii_digit;
        input [7:0] value;
        begin
            ascii_digit = "0" + value;
        end
    endfunction

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            length_reg <= 0;
            index_reg  <= 0;
            o_tx_data  <= 0;
            o_tx_push  <= 1'b0;
            o_busy     <= 1'b0;
            o_done     <= 1'b0;
        end else begin
            o_tx_push <= 1'b0;
            o_done    <= 1'b0;

            if (i_start && !o_busy) begin
                index_reg <= 0;
                o_busy    <= 1'b1;
                case (i_kind)
                    RESP_ACK: begin
                        message[0] <= "O";
                        message[1] <= "K";
                        message[2] <= 8'h0D;
                        message[3] <= 8'h0A;
                        length_reg <= 4;
                    end

                    RESP_ERROR: begin
                        message[0] <= "E";
                        message[1] <= "R";
                        message[2] <= "R";
                        message[3] <= 8'h0D;
                        message[4] <= 8'h0A;
                        length_reg <= 5;
                    end

                    RESP_SW: begin
                        message[0]  <= "S";
                        message[1]  <= "W";
                        message[2]  <= " ";
                        message[3]  <= ascii_digit(i_sw_hour / 10);
                        message[4]  <= ascii_digit(i_sw_hour % 10);
                        message[5]  <= ":";
                        message[6]  <= ascii_digit(i_sw_min / 10);
                        message[7]  <= ascii_digit(i_sw_min % 10);
                        message[8]  <= ":";
                        message[9]  <= ascii_digit(i_sw_sec / 10);
                        message[10] <= ascii_digit(i_sw_sec % 10);
                        message[11] <= ".";
                        message[12] <= ascii_digit(i_sw_msec / 10);
                        message[13] <= ascii_digit(i_sw_msec % 10);
                        message[14] <= 8'h0D;
                        message[15] <= 8'h0A;
                        length_reg  <= 16;
                    end

                    RESP_WATCH: begin
                        message[0]  <= "T";
                        message[1]  <= "I";
                        message[2]  <= "M";
                        message[3]  <= "E";
                        message[4]  <= " ";
                        message[5]  <= ascii_digit(i_watch_hour / 10);
                        message[6]  <= ascii_digit(i_watch_hour % 10);
                        message[7]  <= ":";
                        message[8]  <= ascii_digit(i_watch_min / 10);
                        message[9]  <= ascii_digit(i_watch_min % 10);
                        message[10] <= ":";
                        message[11] <= ascii_digit(i_watch_sec / 10);
                        message[12] <= ascii_digit(i_watch_sec % 10);
                        message[13] <= 8'h0D;
                        message[14] <= 8'h0A;
                        length_reg  <= 15;
                    end

                    RESP_DIST: begin
                        message[0]  <= "D";
                        message[1]  <= "I";
                        message[2]  <= "S";
                        message[3]  <= "T";
                        message[4]  <= " ";
                        message[5]  <= ascii_digit(i_distance / 100);
                        message[6]  <= ascii_digit((i_distance / 10) % 10);
                        message[7]  <= ascii_digit(i_distance % 10);
                        message[8]  <= "c";
                        message[9]  <= "m";
                        message[10] <= 8'h0D;
                        message[11] <= 8'h0A;
                        length_reg  <= 12;
                    end

                    RESP_DHT11: begin
                        message[0]  <= "T";
                        message[1]  <= "E";
                        message[2]  <= "M";
                        message[3]  <= "P";
                        message[4]  <= " ";
                        message[5]  <= ascii_digit(i_temperature[15:8] / 10);
                        message[6]  <= ascii_digit(i_temperature[15:8] % 10);
                        message[7]  <= ".";
                        message[8]  <= ascii_digit(i_temperature[7:0] / 10);
                        message[9]  <= ascii_digit(i_temperature[7:0] % 10);
                        message[10] <= "C";
                        message[11] <= " ";
                        message[12] <= "H";
                        message[13] <= "U";
                        message[14] <= "M";
                        message[15] <= " ";
                        message[16] <= ascii_digit(i_humidity[15:8] / 10);
                        message[17] <= ascii_digit(i_humidity[15:8] % 10);
                        message[18] <= ".";
                        message[19] <= ascii_digit(i_humidity[7:0] / 10);
                        message[20] <= ascii_digit(i_humidity[7:0] % 10);
                        message[21] <= "%";
                        message[22] <= 8'h0D;
                        message[23] <= 8'h0A;
                        length_reg  <= 24;
                    end

                    default: begin
                        message[0] <= "E";
                        message[1] <= "R";
                        message[2] <= "R";
                        message[3] <= 8'h0D;
                        message[4] <= 8'h0A;
                        length_reg <= 5;
                    end
                endcase
            end else if (o_busy && !i_tx_full) begin
                o_tx_data <= message[index_reg];
                o_tx_push <= 1'b1;
                if (index_reg == length_reg - 1) begin
                    index_reg <= 0;
                    o_busy    <= 1'b0;
                    o_done    <= 1'b1;
                end else begin
                    index_reg <= index_reg + 1'b1;
                end
            end
        end
    end
endmodule
