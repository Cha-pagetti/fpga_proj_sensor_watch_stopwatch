`timescale 1ns / 1ps


module ascii_decoder (
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

module uart_loop_back (
    input        clk,
    input        reset,
    input        rx,
    output       tx,
    output [7:0] rx_data,
    output       rx_done
);

    wire w_baud_tick_x16;
    wire [7:0] w_rx_data;
    wire w_rx_done;

    assign rx_data = w_rx_data;
    assign rx_done = w_rx_done;

    baud_tick_x16 U_BAUD_TICK_x16 (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(w_baud_tick_x16)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .tx_start(w_rx_done),
        .tx_data(w_rx_data),
        .tx(tx),
        .tx_busy(),
        .tx_done()
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );
endmodule
