`timescale 1ns / 1ps

// Integration-owned glue around the teammate-owned UART RX and FIFO modules.
// No UART/FIFO source is modified here.
module integration_uart_rx_bridge #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE   = 9_600,
    parameter integer FIFO_WIDTH  = 4,
    parameter integer BAUD_DIV    = CLK_FREQ_HZ / (BAUD_RATE * 16)
) (
    input        clk,
    input        reset,
    input        rx,
    output [7:0] o_rx_data,
    output       o_rx_empty,
    input        i_rx_pop,
    output       o_rx_overflow
);
    wire baud_tick_x16;
    wire [7:0] rx_data;
    wire rx_done;
    wire rx_full;
    wire rx_is_cr;
    wire rx_is_lf;
    wire rx_fifo_push;
    wire [7:0] rx_fifo_data;
    reg suppress_lf_after_cr_reg;

    // Serial terminals may terminate a line with LF, CR, or CRLF, while the
    // teammate decoder accepts LF only. Normalize CR to LF and discard the LF
    // immediately following a CR so every convention produces one terminator.
    assign rx_is_cr = (rx_data == 8'h0D);
    assign rx_is_lf = (rx_data == 8'h0A);
    assign rx_fifo_push = rx_done &&
                          !(suppress_lf_after_cr_reg && rx_is_lf);
    assign rx_fifo_data = rx_is_cr ? 8'h0A : rx_data;

    assign o_rx_overflow = rx_fifo_push && rx_full;

    always @(posedge clk, posedge reset) begin
        if (reset)
            suppress_lf_after_cr_reg <= 1'b0;
        else if (rx_done)
            suppress_lf_after_cr_reg <= rx_is_cr;
    end

    baud_tick_x16 #(
        .F_COUNT(BAUD_DIV)
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
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    fifo #(
        .WIDTH(FIFO_WIDTH)
    ) U_RX_FIFO (
        .clk(clk),
        .reset(reset),
        .wData(rx_fifo_data),
        .push(rx_fifo_push),
        .pop(i_rx_pop),
        .rData(o_rx_data),
        .full(rx_full),
        .empty(o_rx_empty)
    );
endmodule
