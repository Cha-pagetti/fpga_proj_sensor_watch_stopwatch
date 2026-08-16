`timescale 1ns / 1ps


module uart_fifo_loopback (
    input  clk,
    input  reset,
    input  rx,
    output tx
);

    wire w_baud_tick_x16;
    wire [7:0] w_rx_data;
    wire w_rx_done;

    wire [7:0] w_fifo_rx_data, w_fifo_tx_data;
    wire w_fifo_rx_empty, w_fifo_tx_full, w_fifo_tx_empty;
    wire w_tx_busy;

    baud_tick_x16 U_BAUD_TICK_x16 (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(w_baud_tick_x16)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    fifo #(2) U_FIFO_RX (
        .clk  (clk),
        .reset(reset),
        .wData(w_rx_data),
        .push (w_rx_done),
        .pop  (!w_fifo_tx_full),
        .rData(w_fifo_rx_data),
        .full (),
        .empty(w_fifo_rx_empty)
    );

    fifo #(2) U_FIFO_TX (
        .clk  (clk),
        .reset(reset),
        .wData(w_fifo_rx_data),
        .push (!w_fifo_rx_empty),
        .pop  (!w_tx_busy),
        .rData(w_fifo_tx_data),
        .full (w_fifo_tx_full),
        .empty(w_fifo_tx_empty)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .tx_start(!w_fifo_tx_empty),
        .tx_data(w_fifo_tx_data),
        .tx(tx),
        .tx_busy(w_tx_busy),
        .tx_done()
    );

endmodule


// module uart_loop_back (
//     input        clk,
//     input        reset,
//     input        rx,
//     output       tx,
//     output [7:0] rx_data,
//     output       rx_done
// );

//     wire w_baud_tick_x16;
//     wire [7:0] w_rx_data;
//     wire w_rx_done;

//     assign rx_data = w_rx_data;
//     assign rx_done = w_rx_done;

//     baud_tick_x16 U_BAUD_TICK_x16 (
//         .clk(clk),
//         .reset(reset),
//         .o_baud_tick(w_baud_tick_x16)
//     );

//     uart_tx U_UART_TX (
//         .clk(clk),
//         .reset(reset),
//         .i_baud_tick(w_baud_tick_x16),
//         .tx_start(w_rx_done),
//         .tx_data(w_rx_data),
//         .tx(tx),
//         .tx_busy(),
//         .tx_done()
//     );

//     uart_rx U_UART_RX (
//         .clk(clk),
//         .reset(reset),
//         .i_baud_tick(w_baud_tick_x16),
//         .rx(rx),
//         .rx_data(w_rx_data),
//         .rx_done(w_rx_done)
//     );
// endmodule
