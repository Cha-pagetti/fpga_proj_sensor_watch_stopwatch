`timescale 1ns / 1ps

module tb_sr04_controller ();

    reg clk, reset, i_start, echo;
    wire trigger, o_done, o_ready, o_error;
    wire [8:0] distance;


    sr04_controller_origin dut (
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

    always #5 clk = ~clk;

    // 1us 단위로 입력
    task SRO4_TASK(input [$clog2(60_000)-1:0] wait_time,
                   input [$clog2(23_200):0] high_time);
        begin
            @(negedge clk);
            i_start = 1;
            @(negedge clk);
            i_start = 0;

            @(negedge trigger);
            #(wait_time * 1_000);

            echo = 1;
            #(high_time * 1_000);
            @(negedge clk);
            echo = 0;
        end
    endtask

    integer i;
    integer wait_time, high_time;

    initial begin
        clk = 0;
        reset = 1;
        i_start = 0;
        echo = 0;
        wait_time = 0;
        high_time = 0;
        i = 0;
        #10;
        reset = 0;

        // SRO4_TASK(200, 580);
        // SRO4_TASK(200, 58);
        // SRO4_TASK(200, 57);
        // SRO4_TASK(200, 5800);
        // SRO4_TASK(200, 5799);

        for (i = 0; i < 100; i = i + 1) begin
            wait_time = $urandom % 1_000;
            high_time = $urandom % 37_000;
            #10;

            $display("%t #%d:\twait_time = %d,\thigh_time = %d", $time, i,
                     wait_time, high_time);
            if (high_time >= 36_000)
                $display("%t #%d: invaild echo start", $time, i);
            SRO4_TASK(wait_time, high_time);
            @(negedge o_done);
            $display("%t #%d:\tdetected high_time = %d,\tdistance = %d", $time, i,
                     distance * 58, distance);
            #11_000_000;
        end

        #10_000;
        $stop;
    end
endmodule

module tb_sr04_example ();
    reg clk, reset, i_start, echo;
    wire trigger, o_done;
    wire [8:0] distance;

    sr04_controller_example dut (
        .clk(clk),
        .reset(reset),
        .i_start(i_start),
        .echo(echo),
        .trigger(trigger),
        .o_done(o_done),
        .distance(distance)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        i_start = 0;
        echo = 0;
        #10;
        reset = 1;


        @(negedge clk);
        i_start = 1;
        #10;
        i_start = 0;

        @(negedge trigger);
        #200_000;

        echo = 1;
        @(negedge clk);
        echo = 0;
    end

endmodule
