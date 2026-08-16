`timescale 1ns / 1ps

module ascii_decoder (
    input        clk,
    input        reset,
    input  [7:0] i_data,
    output       o_get,
    output       o_op,
    output [9:0] o_signals,
    output [3:0] o_target,
    output       o_done
);

    localparam [1:0] IDLE = 0;
    localparam [1:0] COMMAND = 1;
    localparam [1:0] TARGET = 2;
    localparam [1:0] DONE = 3;

    reg [1:0] c_state, n_state;

    reg [79:0] command_reg, command_next;

    reg get_reg, get_next;
    reg op_reg, op_next;
    reg done_reg, done_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state     <= IDLE;
            command_reg <= 0;
            get_reg     <= 0;
            op_reg      <= 0;
            done_reg    <= 0;
        end else begin
            c_state     <= n_state;
            command_reg <= command_next;
            get_reg     <= get_next;
            op_reg      <= op_next;
            done_reg    <= done_next;
        end
    end

    always @(*) begin
        n_state      = c_state;
        command_next = command_reg;
        get_next     = get_reg;
        op_next      = op_reg;
        done_next    = done_reg;
        case (c_state)
            IDLE: begin
                command_next = 0;
                op_next = 0;
                get_reg = 0;
            end
            COMMAND: begin

            end
            TARGET: begin

            end
            DONE: begin

            end
        endcase
    end


endmodule

module ascii_decoder_origin (
    input  [7:0] i_data,
    output reg [9:0] o_signals
    // output       run,
    // output       stop,
    // output       clear,
    // output       mode,
    // output       up,
    // output       down,
    // output       left,
    // output       right
);
    //    assign {run, stop, clear, mode, up, down, left, right} = o_signals;

    always @(*) begin
        // 기본값: 전체 0
        o_signals = 10'b0000_0000_00;
        case (i_data)
            8'h72: o_signals = 10'b1000_0000_00;  // ascii r (run)
            8'h73: o_signals = 10'b0100_0000_00;  // ascii s (stop)
            8'h63: o_signals = 10'b0010_0000_00;  // ascii c (clear)
            8'h6d: o_signals = 10'b0001_0000_00;  // ascii m (mode)
            8'h55: o_signals = 10'b0000_1000_00;  // ascii U (up)
            8'h44: o_signals = 10'b0000_0100_00;  // ascii D (down)
            8'h4c: o_signals = 10'b0000_0010_00;  // ascii L (left)
            8'h52: o_signals = 10'b0000_0001_00;  // ascii R (right)
            8'h30: o_signals = 10'b0000_0000_10;  // ascii 0 (save)
            8'h31: o_signals = 10'b0000_0000_01;  // ascii 1 (load)
        endcase
    end

endmodule