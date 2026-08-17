`timescale 1ns / 1ps

module top_sr04 (
    input clk,
    input reset,
    input btn_D,
    input echo,
    output trigger,
    output [1:0] led,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_start;
    wire [8:0] w_distance;

    btn_debouncer U_BD (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_start)
    );

    sr04_controller U_SR04_CNTL (
        .clk(clk),
        .reset(reset),
        .i_start(w_start),
        .echo(echo),
        .trigger(trigger),
        .o_done(),
        .o_ready(led[0]),
        .o_error(led[1]),
        .distance(w_distance)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .reset(reset),
        .fnd_in(w_distance),  // distance 받기 위해 9bit로 변경
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );
endmodule
