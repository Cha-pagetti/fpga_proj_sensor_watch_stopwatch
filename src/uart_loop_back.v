`timescale 1ns / 1ps

// UART endpoint with independent RX and TX FIFOs.
module uart_fifo_bridge #(
    parameter integer CLK_FREQ_HZ  = 100_000_000,
    parameter integer BAUD_RATE    = 9_600,
    parameter integer FIFO_WIDTH   = 4
) (
    input        clk,
    input        reset,
    input        rx,
    output       tx,

    output [7:0] o_rx_data,
    output       o_rx_empty,
    input        i_rx_pop,
    output       o_rx_overflow,

    input  [7:0] i_tx_data,
    input        i_tx_push,
    output       o_tx_full
);
    wire baud_tick_x16;
    wire [7:0] uart_rx_data;
    wire uart_rx_done;
    wire rx_fifo_full;

    wire [7:0] tx_fifo_data;
    wire tx_fifo_empty;
    wire uart_tx_busy;
    wire uart_tx_start;

    assign o_rx_overflow = uart_rx_done && rx_fifo_full;
    assign uart_tx_start = !uart_tx_busy && !tx_fifo_empty;

    baud_tick_x16 #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) U_BAUD_TICK_X16 (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(baud_tick_x16)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(baud_tick_x16),
        .rx(rx),
        .rx_data(uart_rx_data),
        .rx_done(uart_rx_done)
    );

    fifo #(
        .WIDTH(FIFO_WIDTH)
    ) U_RX_FIFO (
        .clk(clk),
        .reset(reset),
        .wData(uart_rx_data),
        .push(uart_rx_done),
        .pop(i_rx_pop),
        .rData(o_rx_data),
        .full(rx_fifo_full),
        .empty(o_rx_empty)
    );

    fifo #(
        .WIDTH(FIFO_WIDTH)
    ) U_TX_FIFO (
        .clk(clk),
        .reset(reset),
        .wData(i_tx_data),
        .push(i_tx_push),
        .pop(uart_tx_start),
        .rData(tx_fifo_data),
        .full(o_tx_full),
        .empty(tx_fifo_empty)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(baud_tick_x16),
        .tx_start(uart_tx_start),
        .tx_data(tx_fifo_data),
        .tx(tx),
        .tx_busy(uart_tx_busy),
        .tx_done()
    );
endmodule

// Compatibility loopback top retained for isolated UART/FIFO board tests.
module uart_fifo_loopback #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE   = 9_600
) (
    input  clk,
    input  reset,
    input  rx,
    output tx
);
    wire [7:0] rx_data;
    wire rx_empty;
    wire tx_full;
    wire move_byte;

    assign move_byte = !rx_empty && !tx_full;

    uart_fifo_bridge #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) U_UART_FIFO_BRIDGE (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .o_rx_data(rx_data),
        .o_rx_empty(rx_empty),
        .i_rx_pop(move_byte),
        .o_rx_overflow(),
        .i_tx_data(rx_data),
        .i_tx_push(move_byte),
        .o_tx_full(tx_full)
    );
endmodule
