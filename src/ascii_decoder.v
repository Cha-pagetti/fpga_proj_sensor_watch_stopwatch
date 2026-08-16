`timescale 1ns / 1ps

// Line-oriented UART command decoder.
// CR is ignored and LF terminates a command. Legacy one-byte commands are
// accepted immediately so both the old demo and Open Port Master can be used.
module ascii_decoder (
    input        clk,
    input        reset,
    input        i_fifo_empty,
    input  [7:0] i_data,
    output       o_get,
    output reg   o_op,
    output reg [9:0] o_signals,
    output reg [3:0] o_target,
    output reg   o_done,
    output reg   o_error
);
    localparam integer MAX_BYTES = 16;

    reg [MAX_BYTES*8-1:0] command_reg;
    reg [4:0] byte_count_reg;
    reg overflow_reg;

    assign o_get = !i_fifo_empty;

    task decode_legacy_byte;
        input [7:0] data;
        begin
            case (data)
                "r": o_signals[9] <= 1'b1;
                "s": o_signals[8] <= 1'b1;
                "c": o_signals[7] <= 1'b1;
                "m": o_signals[6] <= 1'b1;
                "0": o_signals[5] <= 1'b1;
                "1": o_signals[4] <= 1'b1;
                "U": o_signals[3] <= 1'b1;
                "D": o_signals[2] <= 1'b1;
                "L": o_signals[1] <= 1'b1;
                "R": o_signals[0] <= 1'b1;
                default: o_error <= 1'b1;
            endcase
        end
    endtask

    task decode_line;
        begin
            o_op <= 1'b0;
            case (command_reg)
                "/run", "/get_run":             o_signals[9] <= 1'b1;
                "/stop", "/get_stop":           o_signals[8] <= 1'b1;
                "/clear", "/get_clear":         o_signals[7] <= 1'b1;
                "/mode", "/get_mode":           o_signals[6] <= 1'b1;
                "/save", "/get_save":           o_signals[5] <= 1'b1;
                "/load", "/get_load":           o_signals[4] <= 1'b1;
                "/up", "/get_up":               o_signals[3] <= 1'b1;
                "/down", "/get_down":           o_signals[2] <= 1'b1;
                "/left", "/get_left":           o_signals[1] <= 1'b1;
                "/right", "/get_right":         o_signals[0] <= 1'b1;

                "/get sw_time", "/get_sw_time", "/get_stopwatch": begin
                    o_op        <= 1'b1;
                    o_target[3] <= 1'b1;
                end
                "/get time", "/get_time": begin
                    o_op        <= 1'b1;
                    o_target[2] <= 1'b1;
                end
                "/get dist", "/get_dist": begin
                    o_op        <= 1'b1;
                    o_target[1] <= 1'b1;
                end
                "/get temp_hum", "/get_temp_hum": begin
                    o_op        <= 1'b1;
                    o_target[0] <= 1'b1;
                end
                default: o_error <= 1'b1;
            endcase
        end
    endtask

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            command_reg    <= 0;
            byte_count_reg <= 0;
            overflow_reg   <= 1'b0;
            o_op           <= 1'b0;
            o_signals      <= 0;
            o_target       <= 0;
            o_done         <= 1'b0;
            o_error        <= 1'b0;
        end else begin
            o_done    <= 1'b0;
            o_error   <= 1'b0;
            o_op      <= 1'b0;
            o_signals <= 0;
            o_target  <= 0;

            if (!i_fifo_empty) begin
                if (i_data == 8'h0D) begin
                    // Ignore CR. LF performs the decode.
                end else if (i_data == 8'h0A) begin
                    if (byte_count_reg != 0 || overflow_reg) begin
                        if (overflow_reg)
                            o_error <= 1'b1;
                        else
                            decode_line();
                        o_done <= 1'b1;
                    end
                    command_reg    <= 0;
                    byte_count_reg <= 0;
                    overflow_reg   <= 1'b0;
                end else if (byte_count_reg == 0 &&
                             (i_data == "r" || i_data == "s" || i_data == "c" ||
                              i_data == "m" || i_data == "0" || i_data == "1" ||
                              i_data == "U" || i_data == "D" || i_data == "L" ||
                              i_data == "R")) begin
                    decode_legacy_byte(i_data);
                    o_done <= 1'b1;
                end else if (byte_count_reg < MAX_BYTES) begin
                    command_reg    <= {command_reg[MAX_BYTES*8-9:0], i_data};
                    byte_count_reg <= byte_count_reg + 1'b1;
                end else begin
                    overflow_reg <= 1'b1;
                end
            end
        end
    end
endmodule
