`timescale 1ns / 1ps

module top_dht11 (
    input clk,
    input reset,
    input btn_D,
    input sw,
    output led,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    inout dht11_io
);
    wire w_btn_down;
    wire w_valid;
    wire [15:0] w_temparature, w_humidity;
    wire [15:0] w_valid_temparature, w_valid_humidity;

    assign w_valid_temparature = (w_valid) ? w_temparature : 0;
    assign w_valid_humidity = (w_valid) ? w_humidity : 0;

    wire [15:0] data;
    // assign data = (sw) ? w_valid_temparature : w_valid_humidity;
    assign data = (sw) ? w_temparature : w_humidity;


    btn_debouncer BD_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_down)
    );

    dht11_controller U_DHT11_CNTL (
        .clk(clk),
        .reset(reset),
        .i_start(w_btn_down),
        .o_done(),
        .o_valid(w_valid),
        .o_ready(led),
        .temperature(w_temparature),
        .humidity(w_humidity),
        .dht11_io(dht11_io)
    );

    fnd_controller_dht11 FND_CNTL (
        .clk(clk),
        .reset(reset),
        .fnd_in(data),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


endmodule
