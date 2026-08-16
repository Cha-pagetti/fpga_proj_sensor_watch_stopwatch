`timescale 1ns / 1ps

// End-to-end UART/FIFO/decoder/control/encoder test through the integrated top.
module tb_top_uart;
    localparam integer CLK_FREQ_HZ = 10_000_000;
    localparam integer BAUD_RATE   = 100_000;
    localparam integer CLK_NS      = 100;
    localparam integer BIT_NS      =
        (CLK_FREQ_HZ / (BAUD_RATE * 16)) * 16 * CLK_NS;

    reg clk, reset, rx;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg [2:0] sw;
    reg sr04_echo;
    wire tx, sr04_trigger, dht11_io;
    wire [3:0] fnd_com, led;
    wire [7:0] fnd_data;

    reg [7:0] response [0:15];
    integer failures;
    integer i;

    top #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE),
        .TIME_TICK_COUNT(10)
    ) dut (
        .clk(clk), .reset(reset), .rx(rx), .tx(tx),
        .btn_L(btn_L), .btn_R(btn_R), .btn_UP(btn_UP), .btn_DOWN(btn_DOWN),
        .sw(sw), .sr04_echo(sr04_echo), .sr04_trigger(sr04_trigger),
        .dht11_io(dht11_io), .fnd_com(fnd_com), .fnd_data(fnd_data), .led(led)
    );

    always #(CLK_NS / 2) clk = ~clk;

    task uart_send_byte;
        input [7:0] value;
        integer bit_index;
        begin
            rx = 1'b0;
            #(BIT_NS);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                rx = value[bit_index];
                #(BIT_NS);
            end
            rx = 1'b1;
            #(BIT_NS);
        end
    endtask

    task uart_send_line;
        input [127:0] text;
        input integer length;
        integer byte_index;
        begin
            for (byte_index = length - 1; byte_index >= 0; byte_index = byte_index - 1)
                uart_send_byte(text[byte_index*8 +: 8]);
            uart_send_byte(8'h0A);
        end
    endtask

    task uart_receive_byte;
        output [7:0] value;
        integer bit_index;
        begin
            @(negedge tx);
            #(BIT_NS / 2);
            if (tx !== 1'b0) begin
                $display("FAIL: invalid UART start bit");
                failures = failures + 1;
            end
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                #(BIT_NS);
                value[bit_index] = tx;
            end
            #(BIT_NS);
            if (tx !== 1'b1) begin
                $display("FAIL: invalid UART stop bit");
                failures = failures + 1;
            end
        end
    endtask

    task receive_response;
        input integer length;
        integer byte_index;
        begin
            for (byte_index = 0; byte_index < length; byte_index = byte_index + 1)
                uart_receive_byte(response[byte_index]);
        end
    endtask

    function is_digit;
        input [7:0] value;
        begin
            is_digit = (value >= "0") && (value <= "9");
        end
    endfunction

    initial begin
        clk = 0; reset = 1; rx = 1;
        btn_L = 0; btn_R = 0; btn_UP = 0; btn_DOWN = 0;
        sw = 0; sr04_echo = 0; failures = 0;
        repeat (8) @(negedge clk);
        reset = 0;

        // Action path: UART RX -> FIFO -> decoder -> control -> encoder -> TX.
        fork
            uart_send_line("/get_run", 8);
            receive_response(4);
        join
        if (response[0] !== "O" || response[1] !== "K" ||
            response[2] !== 8'h0D || response[3] !== 8'h0A) begin
            $display("FAIL: /get_run response = %c%c %h %h",
                     response[0], response[1], response[2], response[3]);
            failures = failures + 1;
        end
        if (!led[0]) begin
            $display("FAIL: /get_run did not leave stopwatch running");
            failures = failures + 1;
        end

        repeat (20) @(negedge clk);

        // Query path returns a complete, structured stopwatch time response.
        fork
            uart_send_line("/get_sw_time", 12);
            receive_response(16);
        join
        if ({response[0], response[1], response[2]} !== "SW " ||
            response[5] !== ":" || response[8] !== ":" ||
            response[11] !== "." || response[14] !== 8'h0D ||
            response[15] !== 8'h0A) begin
            $display("FAIL: malformed stopwatch response");
            failures = failures + 1;
        end
        for (i = 3; i <= 13; i = i + 1) begin
            if (i != 5 && i != 8 && i != 11 && !is_digit(response[i])) begin
                $display("FAIL: non-digit at stopwatch response byte %0d", i);
                failures = failures + 1;
            end
        end

        if (failures == 0)
            $display("TOP UART INTEGRATION TEST PASS");
        else
            $fatal(1, "TOP UART INTEGRATION TEST FAIL: %0d failure(s)", failures);
        $finish;
    end
endmodule
