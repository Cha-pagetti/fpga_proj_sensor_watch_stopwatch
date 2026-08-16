`timescale 1ns / 1ps

module tb_fifo;
    reg clk, reset, push, pop;
    reg [7:0] wData;
    wire [7:0] rData;
    wire full, empty;
    integer failures;

    fifo #(.WIDTH(2)) dut (
        .clk(clk), .reset(reset), .wData(wData), .push(push), .pop(pop),
        .rData(rData), .full(full), .empty(empty)
    );

    always #5 clk = ~clk;

    task push_byte;
        input [7:0] value;
        begin
            @(negedge clk); wData = value; push = 1; pop = 0;
            @(negedge clk); push = 0;
        end
    endtask

    task expect_pop;
        input [7:0] value;
        begin
            @(negedge clk);
            if (rData !== value) begin
                $display("FAIL FIFO expected=%h actual=%h", value, rData);
                failures = failures + 1;
            end
            pop = 1; push = 0;
            @(negedge clk); pop = 0;
        end
    endtask

    initial begin
        clk = 0; reset = 1; push = 0; pop = 0; wData = 0; failures = 0;
        repeat (2) @(negedge clk); reset = 0;

        push_byte(8'h11); push_byte(8'h22); push_byte(8'h33); push_byte(8'h44);
        if (!full) begin
            $display("FAIL FIFO full flag");
            failures = failures + 1;
        end
        // Fifth push is rejected while full.
        push_byte(8'h55);
        expect_pop(8'h11); expect_pop(8'h22); expect_pop(8'h33); expect_pop(8'h44);
        if (!empty) begin
            $display("FAIL FIFO empty flag");
            failures = failures + 1;
        end

        if (failures == 0)
            $display("FIFO TEST PASS");
        else
            $fatal(1, "FIFO TEST FAIL: %0d failure(s)", failures);
        $finish;
    end
endmodule
