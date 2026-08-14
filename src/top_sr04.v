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

    reg echo_sync, echo_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            echo_sync <= 0;
            echo_reg <= 0;
        end else begin
            echo_reg <= echo;
            echo_sync <= echo_reg;
        end
    end

    btn_debouncer U_BD (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_start)
    );

    sr04_controller_origin U_SR04_CNTL (
        .clk(clk),
        .reset(reset),
        .i_start(w_start),
        .echo(echo_sync),
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
