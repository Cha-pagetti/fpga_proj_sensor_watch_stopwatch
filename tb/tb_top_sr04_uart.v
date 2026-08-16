`timescale 1ns / 1ps

// UART RX -> teammate decoder -> project Control Unit -> SR04 integration.
module tb_top_sr04_uart;
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
    integer failures;

    top #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk), .reset(reset), .rx(rx), .tx(tx),
        .btn_L(btn_L), .btn_R(btn_R), .btn_UP(btn_UP), .btn_DOWN(btn_DOWN),
        .sw(sw), .sr04_echo(sr04_echo), .sr04_trigger(sr04_trigger),
        .dht11_io(dht11_io), .fnd_com(fnd_com), .fnd_data(fnd_data), .led(led)
    );

    always #(CLK_NS / 2) clk = ~clk;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("tb_top_sr04_uart.vcd");
        $dumpvars(0, clk, reset, rx, tx, sr04_echo, sr04_trigger,
                  dut.cmd_done, dut.cmd_target, dut.sr04_start,
                  dut.sr04_done, dut.sr04_error, dut.distance,
                  dut.response_valid, dut.response_kind);
    end
`endif

    task uart_send_byte;
        input [7:0] value;
        integer bit_index;
        begin
            rx = 0; #(BIT_NS);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                rx = value[bit_index]; #(BIT_NS);
            end
            rx = 1; #(BIT_NS);
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

    task sensor_echo_10cm;
        begin
            @(negedge sr04_trigger);
            #20_000;
            sr04_echo = 1;
            #580_000;
            sr04_echo = 0;
        end
    endtask

    initial begin
        clk = 0; reset = 1; rx = 1;
        btn_L = 0; btn_R = 0; btn_UP = 0; btn_DOWN = 0;
        sw = 3'b010; sr04_echo = 0; failures = 0;
        repeat (8) @(negedge clk);
        reset = 0;

        // Current teammate decoder syntax is "/get dist\n".
        fork
            uart_send_line("/get dist", 9);
            sensor_echo_10cm();
        join

        wait (dut.response_valid);
        #1;
        if (dut.response_kind !== 3'd4 || dut.distance !== 9'd10) begin
            $display("FAIL: response_kind=%0d distance=%0d",
                     dut.response_kind, dut.distance);
            failures = failures + 1;
        end

        // Keep the final response kind visible long enough for presentation VCDs.
        #100_000;

        if (failures == 0)
            $display("TOP SR04 CONTROL INTEGRATION TEST PASS");
        else
            $fatal(1, "TOP SR04 CONTROL INTEGRATION TEST FAIL: %0d", failures);
        $finish;
    end
endmodule
