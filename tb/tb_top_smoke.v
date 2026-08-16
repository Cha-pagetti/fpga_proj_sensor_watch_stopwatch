`timescale 1ns / 1ps

// Elaboration/reset smoke test for the complete source hierarchy.
module tb_top_smoke;
    reg clk, reset, rx;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg [2:0] sw;
    reg sr04_echo;
    wire tx, sr04_trigger, dht11_io;
    wire [3:0] fnd_com, led;
    wire [7:0] fnd_data;

    top #(
        .CLK_FREQ_HZ(10_000_000),
        .BAUD_RATE(115_200),
        .TIME_TICK_COUNT(10)
    ) dut (
        .clk(clk), .reset(reset), .rx(rx), .tx(tx),
        .btn_L(btn_L), .btn_R(btn_R), .btn_UP(btn_UP), .btn_DOWN(btn_DOWN),
        .sw(sw), .sr04_echo(sr04_echo), .sr04_trigger(sr04_trigger),
        .dht11_io(dht11_io), .fnd_com(fnd_com), .fnd_data(fnd_data), .led(led)
    );

    always #50 clk = ~clk;

    initial begin
        clk = 0; reset = 1; rx = 1;
        btn_L = 0; btn_R = 0; btn_UP = 0; btn_DOWN = 0;
        sw = 0; sr04_echo = 0;
        repeat (5) @(negedge clk);
        reset = 0;
        repeat (100) @(negedge clk);
        $display("TOP SMOKE TEST PASS");
        $finish;
    end
endmodule
