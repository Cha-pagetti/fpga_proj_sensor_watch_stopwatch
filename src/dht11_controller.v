`timescale 1ns / 1ps

module dht11_controller (
    input clk,  // system clk
    input reset,  // btn_C와 연결
    input i_start,  // btn_D와 연결
    output        o_done,       // IO, 데이터 검사, period 지남 완료시 1clk 동안 1
    output o_valid,  // checksum 검사 결과 유효하면 1
    output o_ready,  // 다음 i_start 보낼 수 있으면 1
    output [15:0] temperature,  // 8bit 정수 + 8bit 실수
    output [15:0] humidity,  // 8bit 정수 + 8bit 실수
    inout dht11_io  // dht11과 상호작용하는 port
);

    localparam [4:0] IDLE = 0;
    localparam [4:0] START = 1;
    localparam [4:0] WAIT_TX = 2;
    localparam [4:0] WAIT_RX = 3;
    localparam [4:0] SYNC_L = 4;
    localparam [4:0] SYNC_H = 5;
    localparam [4:0] DATA_L = 6;
    localparam [4:0] DATA_H = 7;
    localparam [4:0] STOP = 8;

    reg [4:0] c_state, n_state;

    // dht11로부터 받는 40bit 데이터의 bit 세는 counter reg
    reg [$clog2(40)-1:0] bit_count_reg, bit_count_next;
    // dht11로부터 MSB부터 차례로 전송받은 데이터 저장 공간
    // 습도 정수 - 실수 / 온도 정수 - 실수 / checksum 순서로 저장됨
    reg [39:0] data_reg, data_next;

    // 상위 16bit -> 습도 데이터
    assign humidity = data_reg[39:24];
    // 다음 16bit -> 온도 데이터
    assign temperature = data_reg[23:8];
    // data[7:0]는 checksum

    // checksum과 비교 연산을 위해 습도, 온도 데이터의 합을 저장하는 reg
    reg [7:0] data_sum_reg, data_sum_next;

    // dht11 센서와의 통신을 위한 control, write data reg
    reg io_control_reg, io_control_next;
    reg dht11_io_reg, dht11_io_next;

    // 3 state buffer
    // io_control == 1: write
    // io_coutrol == 0: read
    assign dht11_io = (io_control_reg) ? dht11_io_reg : 1'bz;

    // STOP에서 1초를 세기 위한 1_000_000 counter reg
    // tick을 세야하는 경우 재사용
    reg [$clog2(1_000_000)-1:0] tick_count_reg, tick_count_next;

    // 약 4ms 내로 끝나는 센서 동작의 오류 발생시
    // 무한 루프 방지를 위한 timeout 카운터
    parameter TIMEOUT = 8_000;
    reg [$clog2(TIMEOUT)-1:0] duration_count_reg, duration_count_next;

    // syncronizer
    reg dht11_input_reg, dht11_input_sync;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            dht11_input_reg  <= 1;
            dht11_input_sync <= 1;
        end else begin
            if (!io_control_reg) begin
                dht11_input_reg  <= dht11_io;
                dht11_input_sync <= dht11_input_reg;
            end
        end
    end

    reg done_reg, done_next;
    reg valid_reg, valid_next;
    reg ready_reg, ready_next;

    assign o_done  = done_reg;
    assign o_valid = valid_reg;
    assign o_ready = ready_reg;

    wire tick_1us;

    // 주기 1us tick을 만드는 tick gen
    tick_gen_1Mhz U_TICK_1MHZ (
        .clk(clk),
        .reset(reset),
        .i_runstop(i_start),
        .i_clear(o_done),
        .o_tick(tick_1us)
    );

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            dht11_io_reg <= 1;
            tick_count_reg <= 0;
            io_control_reg <= 1;
            done_reg <= 0;
            valid_reg <= 0;
            ready_reg <= 1;
            bit_count_reg <= 0;
            data_reg <= 0;
            data_sum_reg <= 0;
            duration_count_reg <= 0;
        end else begin
            c_state <= n_state;
            dht11_io_reg <= dht11_io_next;
            tick_count_reg <= tick_count_next;
            io_control_reg <= io_control_next;
            done_reg <= done_next;
            valid_reg <= valid_next;
            ready_reg <= ready_next;
            bit_count_reg <= bit_count_next;
            data_reg <= data_next;
            data_sum_reg <= data_sum_next;
            duration_count_reg <= duration_count_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        dht11_io_next = dht11_io_reg;
        tick_count_next = tick_count_reg;
        io_control_next = io_control_reg;
        done_next = done_reg;
        valid_next = valid_reg;
        ready_next = ready_reg;
        bit_count_next = bit_count_reg;
        data_next = data_reg;
        data_sum_next = data_sum_reg;
        duration_count_next = duration_count_reg;
        case (c_state)
            IDLE: begin
                done_next = 0;
                io_control_next = 1;
                dht11_io_next = 1;
                // valid_next = 0;
                ready_next = 1;
                if (i_start) begin
                    n_state = START;
                    dht11_io_next = 0;
                    tick_count_next = 0;
                    valid_next = 0;
                    data_next = 0;
                    bit_count_next = 0;
                    ready_next = 0;
                end
            end
            START: begin
                io_control_next = 1;
                dht11_io_next   = 0;
                if (tick_1us) begin
                    duration_count_next = duration_count_reg + 1;
                    tick_count_next = tick_count_reg + 1;
                    if (tick_count_reg == 19_000) begin
                        n_state = WAIT_TX;
                        tick_count_next = 0;
                        dht11_io_next = 1;
                    end
                end
            end
            WAIT_TX: begin
                io_control_next = 1;
                dht11_io_next   = 1;
                if (tick_1us) begin
                    tick_count_next = tick_count_reg + 1;
                    if (tick_count_reg == 10) begin
                        n_state = WAIT_RX;
                        io_control_next = 0;
                        tick_count_next = 0;
                        duration_count_next = 0;
                    end
                end
            end
            WAIT_RX: begin
                io_control_next = 0;
                if (tick_1us) begin
                    duration_count_next = duration_count_reg + 1;
                    if (duration_count_reg == TIMEOUT) begin
                        n_state = IDLE;
                        done_next = 1;
                        valid_next = 0;
                        ready_next = 1;
                        duration_count_next = 0;
                    end
                end
                if (!dht11_input_sync) begin
                    n_state = SYNC_L;
                end
            end
            SYNC_L: begin
                io_control_next = 0;
                if (tick_1us) begin
                    duration_count_next = duration_count_reg + 1;
                    if (duration_count_reg == TIMEOUT) begin
                        n_state = IDLE;
                        done_next = 1;
                        valid_next = 0;
                        ready_next = 1;
                        duration_count_next = 0;
                    end
                end
                if (dht11_input_sync) begin
                    n_state = SYNC_H;
                end
            end
            SYNC_H: begin
                io_control_next = 0;
                if (tick_1us) begin
                    duration_count_next = duration_count_reg + 1;
                    if (duration_count_reg == TIMEOUT) begin
                        n_state = IDLE;
                        done_next = 1;
                        valid_next = 0;
                        ready_next = 1;
                        duration_count_next = 0;
                    end
                end
                if (!dht11_input_sync) begin
                    n_state = DATA_L;
                end
            end
            DATA_L: begin
                io_control_next = 0;
                if (tick_1us) begin
                    duration_count_next = duration_count_reg + 1;
                    if (duration_count_reg == TIMEOUT) begin
                        n_state = IDLE;
                        done_next = 1;
                        valid_next = 0;
                        ready_next = 1;
                        duration_count_next = 0;
                    end
                end
                if (dht11_input_sync) begin
                    n_state = DATA_H;
                end
            end
            DATA_H: begin
                if (tick_1us) begin
                    duration_count_next = duration_count_reg + 1;
                    if (duration_count_reg == TIMEOUT) begin
                        n_state = IDLE;
                        done_next = 1;
                        valid_next = 0;
                        ready_next = 1;
                        duration_count_next = 0;
                    end

                    tick_count_next = tick_count_reg + 1;
                    if (!dht11_input_sync) begin
                        if (tick_count_reg > 50) begin
                            data_next[39-bit_count_reg] = 1;
                        end else begin
                            data_next[39-bit_count_reg] = 0;
                        end
                        if (bit_count_reg == 39) begin
                            n_state = STOP;
                            tick_count_next = 0;
                            bit_count_next = 0;
                            data_sum_next = data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8];
                        end else begin
                            n_state = DATA_L;
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;
                        end
                    end
                end
            end
            STOP: begin
                if (tick_1us) begin
                    tick_count_next = tick_count_reg + 1;
                    if (tick_count_reg == 999_999) begin
                        n_state = IDLE;
                        tick_count_next = 0;
                        bit_count_next = 0;
                        io_control_next = 1;
                        dht11_io_next = 1;
                        done_next = 1;
                        ready_next = 1;
                        if (data_sum_reg == data_reg[7:0]) valid_next = 1;
                        else valid_next = 0;
                    end
                end
            end
        endcase
    end
endmodule

module dht11 (
    input         clk,
    input         reset,
    input         i_start,
    output [15:0] humidty,
    output [15:0] temperature,
    output        done,
    output        vaild,
    inout         dht11_io
);

    localparam [3:0] IDLE = 0;
    localparam [3:0] START = 1;
    localparam [3:0] WAIT = 2;
    localparam [3:0] SYNC = 3;
    // localparam [3:0] SYNC_H = 4;
    localparam [3:0] DATA = 5;
    // localparam [3:0] DATA_H = 6;
    localparam [3:0] STOP = 7;

    reg [3:0] c_state, n_state;

    reg io_control;
    reg dht11_io_reg, dht11_io_next;

    assign dht11_io = (io_control) ? dht11_io_reg : 1'bz;

    reg [$clog2(19_000)-1:0] tick_count_next, tick_count_reg;
    reg tick_1us;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            dht11_io_reg <= 1'b1;
            tick_count_reg <= 0;
        end else begin
            c_state <= n_state;
            dht11_io_reg <= dht11_io_next;
            tick_count_reg <= tick_count_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        dht11_io_next = dht11_io_reg;
        tick_count_next = tick_count_reg;
        io_control = 1'b1;
        case (c_state)
            IDLE: begin
                dht11_io_next = 1'b1;
                io_control = 1'b1;
                if (i_start) begin
                    n_state = START;
                end
            end
            START: begin
                dht11_io_next = 1'b0;
                io_control = 1'b1;
                // 19ms low 유지
                if (tick_1us) begin
                    tick_count_next = tick_count_reg + 1;
                end
                if (tick_count_reg == 19_000) begin
                    n_state = WAIT;
                    tick_count_next = 0;
                end
            end
            WAIT: begin
                if (tick_1us) begin
                    if (tick_count_reg == 3) begin
                        n_state = SYNC;
                        tick_count_next = 0;
                        // io_control = 1'b0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            SYNC: begin
                io_control = 0;
                if (tick_count_reg > 3 && !dht11_io) begin
                    n_state = DATA;
                end else begin
                    tick_count_next = tick_count_reg + 1;
                end
            end
            DATA: begin
                n_state = STOP;
            end
            STOP: begin
                if (tick_count_reg > 5) begin
                    n_state = IDLE;
                    io_control = 1'b1;
                end
            end
        endcase
    end

endmodule


module tick_gen_1Mhz (
    input clk,
    input reset,
    input i_runstop,
    input i_clear,
    output reg o_tick
);

    parameter F_COUNT = 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 0;
        end else begin
            if (counter_reg >= F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick <= 1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick <= 0;
            end
        end
    end
endmodule
