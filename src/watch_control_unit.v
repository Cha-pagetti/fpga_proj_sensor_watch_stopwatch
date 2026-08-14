`timescale 1ns / 1ps

module watch_control_unit (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    output [1:0] state
);

    parameter START = 2'b00;
    parameter HOUR = 2'b01;
    parameter MIN = 2'b10;
    parameter SEC = 2'b11;

    reg [1:0] current_state, next_state;
    assign state = current_state;


    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= START;
        end else begin
            current_state <= next_state;
        end
    end

    //next combination logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            START:
            if (btn_R == 1) next_state = HOUR;
            else if (btn_L == 1) next_state = SEC;

            HOUR:
            if (btn_R == 1) next_state = MIN;
            else if (btn_L == 1) next_state = START;

            MIN:
            if (btn_R == 1) next_state = SEC;
            else if (btn_L == 1) next_state = HOUR;
            SEC:
            if (btn_R == 1) next_state = START;
            else if (btn_L == 1) next_state = MIN;
            //default: 
        endcase
    end

endmodule


