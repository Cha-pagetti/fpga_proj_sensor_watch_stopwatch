`timescale 1ns / 1ps

module tb_sr04_controller;
    localparam integer CLK_FREQ_HZ = 10_000_000;

    reg clk;
    reg reset;
    reg i_start;
    reg echo;
    wire trigger;
    wire o_done;
    wire o_ready;
    wire o_error;
    wire [8:0] distance;

    integer failures;
    integer trigger_edges;
    time trigger_rise_time;

    sr04_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .ECHO_START_TIMEOUT_US(300),
        .REARM_US(50)
    ) dut (
        .clk(clk),
        .reset(reset),
        .i_start(i_start),
        .echo(echo),
        .trigger(trigger),
        .o_done(o_done),
        .o_ready(o_ready),
        .o_error(o_error),
        .distance(distance)
    );

    always #50 clk = ~clk;

    always @(posedge trigger)
        begin
            trigger_rise_time = $time;
            trigger_edges = trigger_edges + 1;
        end

`ifdef DUMP_VCD
    initial begin
        $dumpfile("tb_sr04_controller.vcd");
        $dumpvars(0, clk, reset, i_start, echo, trigger, o_done,
                  o_ready, o_error, distance, dut.state_reg,
                  dut.wait_count_reg, dut.echo_count_reg,
                  dut.rearm_count_reg, dut.cm_count_reg);
    end
`endif

    always @(negedge trigger) begin
        if (!reset && ($time - trigger_rise_time != 10_000)) begin
            $display("FAIL: trigger width = %0t ns", $time - trigger_rise_time);
            failures = failures + 1;
        end
    end

    task start_measurement;
        begin
            wait (o_ready);
            @(negedge clk);
            i_start = 1'b1;
            @(negedge clk);
            i_start = 1'b0;
            @(negedge trigger);
        end
    endtask

    task valid_echo;
        input integer echo_high_us;
        input integer expected_cm;
        begin
            start_measurement();
            repeat (200) @(negedge clk); // 20 us sensor response delay
            echo = 1'b1;
            #(echo_high_us * 1000);
            echo = 1'b0;
            @(posedge o_done);
            #1;
            if (distance !== expected_cm[8:0]) begin
                $display("FAIL: echo=%0d us expected=%0d cm actual=%0d cm",
                         echo_high_us, expected_cm, distance);
                failures = failures + 1;
            end else begin
                $display("PASS: echo=%0d us distance=%0d cm", echo_high_us, distance);
            end
            wait (o_ready);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        i_start = 1'b0;
        echo = 1'b0;
        failures = 0;
        trigger_edges = 0;

        repeat (4) @(negedge clk);
        reset = 1'b0;

        // SCN-SR04-01: distance quantization boundaries.
        valid_echo(57, 0);
        valid_echo(58, 1);
        valid_echo(600, 10);
        valid_echo(5_820, 100);
        valid_echo(23_150, 399);

        // SCN-SR04-02: a repeated start while measuring is ignored.
        start_measurement();
        repeat (200) @(negedge clk);
        echo = 1;
        #100_000;
        @(negedge clk); i_start = 1;
        @(negedge clk); i_start = 0;
        #480_000;
        echo = 0;
        @(posedge o_done); #1;
        if (distance !== 9'd10) begin
            $display("FAIL: busy start disturbed measurement");
            failures = failures + 1;
        end
        wait (o_ready);

        // SCN-SR04-03: missing echo must timeout instead of hanging.
        start_measurement();
        @(posedge o_error);
        #1;
        if (distance !== 0) begin
            $display("FAIL: timeout did not clear distance");
            failures = failures + 1;
        end else begin
            $display("PASS: missing echo timeout");
        end

        // SCN-SR04-04: an overlong echo reports an error and clears distance.
        wait (o_ready);
        start_measurement();
        repeat (200) @(negedge clk);
        echo = 1;
        @(posedge o_error); #1;
        echo = 0;
        if (distance !== 0) begin
            $display("FAIL: overlong echo did not clear distance");
            failures = failures + 1;
        end

        // SCN-SR04-05: start during re-arm is ignored.
        @(negedge clk); i_start = 1;
        @(negedge clk); i_start = 0;
        wait (o_ready);
        repeat (5) @(negedge clk);
        if (trigger || trigger_edges != 8) begin
            $display("FAIL: re-arm start was not ignored");
            failures = failures + 1;
        end

        wait (o_ready);
        if (failures == 0)
            $display("SR04 TEST PASS");
        else
            $fatal(1, "SR04 TEST FAIL: %0d failure(s)", failures);
        $finish;
    end
endmodule
