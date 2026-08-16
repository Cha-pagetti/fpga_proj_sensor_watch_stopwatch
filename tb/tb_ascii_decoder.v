`timescale 1ns / 1ps

module tb_ascii_decoder ();

    // 9600bps * 8 (8bit 모두 도착할 때까지의 시간)
    parameter BUAD_TICK = (100_000_000 / 9600) * 10 * 8;

    reg clk, reset;
    reg [7:0] wData;
    reg push;
    wire pop;
    wire [7:0] rData;
    wire full, empty;

    wire op;
    wire [9:0] signals;
    wire [3:0] target;
    wire done;

    fifo #(4) dut_FIFO (
        .clk  (clk),
        .reset(reset),
        .wData(wData),
        .push (push),
        .pop  (pop),
        .rData(rData),
        .full (full),
        .empty(empty)
    );

    ascii_decoder dut (
        .clk(clk),
        .reset(reset),
        .i_fifo_empty(empty),
        .i_data(rData),
        .o_get(pop),
        .o_op(op),
        .o_signals(signals),
        .o_target(target),
        .o_done(done)
    );

    task PUSH_DATA_TASK(input [7:0] i_data);
        begin
            @(negedge clk);
            push = 1;
            wData = i_data;
            #10;
            push = 0;
            #(BUAD_TICK);
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        wData = 0;
        push  = 0;
        #10;
        reset = 0;

        PUSH_DATA_TASK("r");
        PUSH_DATA_TASK("\n");
        
        PUSH_DATA_TASK("s");
        PUSH_DATA_TASK("\n");
        
        PUSH_DATA_TASK("m");
        PUSH_DATA_TASK("\n");

        PUSH_DATA_TASK("c");
        PUSH_DATA_TASK("\n");

        PUSH_DATA_TASK("0");
        PUSH_DATA_TASK("\n");

        PUSH_DATA_TASK("1");
        PUSH_DATA_TASK("\n");
        
        PUSH_DATA_TASK("U");
        PUSH_DATA_TASK("\n");
        PUSH_DATA_TASK("D");
        PUSH_DATA_TASK("\n");
        PUSH_DATA_TASK("L");
        PUSH_DATA_TASK("\n");
        PUSH_DATA_TASK("R");
        PUSH_DATA_TASK("\n");
        
        PUSH_DATA_TASK("/");
        PUSH_DATA_TASK("g");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK(8'h20);
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK("i");
        PUSH_DATA_TASK("m");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("\n");

        PUSH_DATA_TASK("/");
        PUSH_DATA_TASK("g");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK(8'h20);
        PUSH_DATA_TASK("s");
        PUSH_DATA_TASK("w");
        PUSH_DATA_TASK("_");
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK("i");
        PUSH_DATA_TASK("m");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("\n");

        PUSH_DATA_TASK("/");
        PUSH_DATA_TASK("g");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK(8'h20);
        PUSH_DATA_TASK("d");
        PUSH_DATA_TASK("i");
        PUSH_DATA_TASK("s");
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK("\n");

        PUSH_DATA_TASK("/");
        PUSH_DATA_TASK("g");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK(8'h20);
        PUSH_DATA_TASK("t");
        PUSH_DATA_TASK("e");
        PUSH_DATA_TASK("m");
        PUSH_DATA_TASK("p");
        PUSH_DATA_TASK("_");
        PUSH_DATA_TASK("h");
        PUSH_DATA_TASK("u");
        PUSH_DATA_TASK("m");
        PUSH_DATA_TASK("\n");
        
        $stop;
    end
endmodule
