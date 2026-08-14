`timescale 1ns / 1ps

module tb_dht11 ();

    reg clk, reset, i_start;
    reg [39:0] sensor_data;
    wire [15:0] humidity, temperature;
    wire done, valid, ready;
    wire dht11_io;

    reg dht11_sensor_io, dht_sensor_io_control;
    integer i, j, pass_cnt, fail_cnt;
    reg [7:0] humidity_int, humidity_de, temperature_int, temperature_de;

    // dht11 센서 기능 모사
    assign dht11_io = (dht_sensor_io_control) ? dht11_sensor_io : 1'bz;

    dht11_controller dut (
        .clk(clk),
        .reset(reset),
        .i_start(i_start),
        .humidity(humidity),
        .temperature(temperature),
        .o_done(done),
        .o_valid(valid),
        .o_ready(ready),
        .dht11_io(dht11_io)
    );

    always #5 clk = ~clk;


    task DHT11_SENSOR_TASK(input [31:0] i_data);
        begin
            // IDLE
            #10;

            // START
            i_start = 1;
            #10;
            i_start = 0;
            #19_000_000;  // 19ms

            // WAIT TX
            #30_000;  // 30us

            // WAIT RX
            dht_sensor_io_control = 1'b1;  // DHT 입력 시작

            // sync low
            dht11_sensor_io = 1'b0;
            #80_000;

            // sync high
            dht11_sensor_io = 1'b1;
            #80_000;

            // DATA (checksum 계산)
            sensor_data = {
                i_data,
                i_data[31:24] + i_data[23:16] + i_data[15:8] + i_data[7:0]
            };
            for (i = 0; i < 40; i = i + 1) begin
                // DATA LOW
                dht11_sensor_io = 1'b0;
                #50_000;

                // DATA HIGH
                dht11_sensor_io = 1'b1;
                if (sensor_data[39-i]) begin
                    #70_000;
                end else begin
                    #27_000;
                end
            end

            // STOP
            dht11_sensor_io = 1'b0;
            #50_000;
            dht11_sensor_io = 1'b1;

            dht_sensor_io_control = 1'b0;  // DHT 입력 끝

            // 1sec 기다림
            #1_000_000_000;
        end
    endtask

    initial begin
        clk                   = 0;
        reset                 = 1;
        i_start               = 0;
        sensor_data           = 0;
        dht11_sensor_io       = 1'b1;
        dht_sensor_io_control = 1'b0;  // MCU 입력 기다림
        i                     = 0;
        j                     = 0;

        humidity_int          = 0;
        humidity_de           = 0;
        temperature_int       = 0;
        temperature_de        = 0;
        #10;
        reset = 0;

        for (j = 0; j < 20; j = j + 1) begin
            humidity_int    = $urandom % 100;
            humidity_de     = $urandom % 100;
            temperature_int = $urandom % 100;
            temperature_de  = $urandom % 100;


            $display("%t #%d\t: humid = %d.%d, \ttemperature = %d.%d", $time,
                     j, humidity_int, humidity_de, temperature_int,
                     temperature_de);

            DHT11_SENSOR_TASK(
                {humidity_int, humidity_de, temperature_int, temperature_de});

            if (valid) begin
                $display("%t #%d\t: PASS", $time, j);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("%t #%d\t: FAIL", $time, j);
                fail_cnt = fail_cnt + 1;
            end

            $display("%t #%d\t: humid = %d.%d, \ttemperature = %d.%d", $time,
                     j, humidity[15:8], humidity[7:0], temperature[15:8],
                     temperature[7:0]);
            #10;
        end

        // #10;
        // i_start = 1;
        // #10;
        // i_start = 0;
        // #19_000_000;  // 19ms
        // #30_000;  // 30us

        // dht_sensor_io_control = 1'b1;  // DHT 입력 시작

        // dht11_sensor_io = 1'b0;
        // #80_000;  // sync low
        // dht11_sensor_io = 1'b1;
        // #80_000;  // sync high

        // sensor_data = {8'h19, 8'h00, 8'h19, 8'h00, 8'h32};
        // // data
        // for (i = 0; i < 40; i = i + 1) begin
        //     dht11_sensor_io = 1'b0;
        //     #50_000;
        //     dht11_sensor_io = 1'b1;
        //     if (sensor_data[39-i]) begin
        //         #70_000;
        //     end else begin
        //         #27_000;
        //     end
        // end

        // dht11_sensor_io = 1'b0;
        // #50_000;
        // dht11_sensor_io = 1'b1;

        // dht_sensor_io_control = 1'b0;  // DHT 입력 끝
    end

endmodule
