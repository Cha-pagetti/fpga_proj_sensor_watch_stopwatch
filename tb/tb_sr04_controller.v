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
        trigger_rise_time = $time;

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

        repeat (4) @(negedge clk);
        reset = 1'b0;

        valid_echo(600, 10);
        valid_echo(5_820, 100);
        valid_echo(23_150, 399);

        // Missing echo must terminate with an error instead of hanging.
        start_measurement();
        @(posedge o_error);
        #1;
        if (distance !== 0) begin
            $display("FAIL: timeout did not clear distance");
            failures = failures + 1;
        end else begin
            $display("PASS: missing echo timeout");
        end

        wait (o_ready);
        if (failures == 0)
            $display("SR04 TEST PASS");
        else
            $fatal(1, "SR04 TEST FAIL: %0d failure(s)", failures);
        $finish;
    end
endmodule
