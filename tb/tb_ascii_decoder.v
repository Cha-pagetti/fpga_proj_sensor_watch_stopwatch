`timescale 1ns / 1ps

module tb_ascii_decoder;
    reg clk;
    reg reset;
    reg fifo_empty;
    reg [7:0] data;
    wire get;
    wire op;
    wire [9:0] signals;
    wire [3:0] target;
    wire done;
    wire error;
    integer failures;
    integer i;

    ascii_decoder dut (
        .clk(clk), .reset(reset), .i_fifo_empty(fifo_empty), .i_data(data),
        .o_get(get), .o_op(op), .o_signals(signals), .o_target(target),
        .o_done(done), .o_error(error)
    );

    always #5 clk = ~clk;

    task send_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            data = value;
            fifo_empty = 1'b0;
            @(negedge clk);
            fifo_empty = 1'b1;
        end
    endtask

    task send_line;
        input [127:0] text;
        input integer length;
        begin
            for (i = length - 1; i >= 0; i = i - 1)
                send_byte(text[i*8 +: 8]);
            send_byte(8'h0A);
        end
    endtask

    task expect_decode;
        input [9:0] expected_signals;
        input [3:0] expected_target;
        input expected_error;
        begin
            #1;
            if (!done || signals !== expected_signals || target !== expected_target ||
                error !== expected_error) begin
                $display("FAIL decode: done=%b signals=%b target=%b error=%b",
                         done, signals, target, error);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        fifo_empty = 1;
        data = 0;
        failures = 0;
        repeat (2) @(negedge clk);
        reset = 0;

        send_line("/get_run", 8);
        expect_decode(10'b10_0000_0000, 4'b0000, 1'b0);

        send_line("/get_dist", 9);
        expect_decode(10'b0, 4'b0010, 1'b0);

        send_line("/get temp_hum", 13);
        expect_decode(10'b0, 4'b0001, 1'b0);

        send_line("/bad", 4);
        expect_decode(10'b0, 4'b0000, 1'b1);

        send_byte("s");
        expect_decode(10'b01_0000_0000, 4'b0000, 1'b0);

        if (failures == 0)
            $display("ASCII DECODER TEST PASS");
        else
            $fatal(1, "ASCII DECODER TEST FAIL: %0d failure(s)", failures);
        $finish;
    end
endmodule
