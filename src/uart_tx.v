`timescale 1ns / 1ps

// uart tx의 top
module uart_controller (
    input        clk,
    input        reset,
    input        tx_start,
    input  [7:0] tx_data,
    input        rx,
    output [7:0] rx_data,
    output       tx_busy,
    output       tx_done,
    output       rx_done,
    output       tx

);
    wire w_baud_tick_x16;

    baud_tick_x16 U_BAUD_TICK_x16 (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(w_baud_tick_x16)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
endmodule

module uart_tx (
    input clk,
    input reset,
    input i_baud_tick,
    input tx_start,
    input [7:0] tx_data,
    output tx,
    output tx_busy,
    output tx_done
);

    // state
    localparam [1:0] IDLE = 2'b00;
    //localparam [2:0] WAIT = 3'b001;  // tx_start는 도착, baud_tick 대기
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA = 2'b10;
    localparam [1:0] STOP = 2'b11;

    reg [1:0] c_state, n_state;
    reg [2:0] bit_count_reg, bit_count_next;
    reg tx_next, tx_reg;

    // x16 baud tick을 위한 0~15 카운터
    reg [3:0] tick_count_reg, tick_count_next;

    // tx_data를 저장하는 레지스터
    reg [7:0] data_reg, data_next;

    reg busy_reg, busy_next;
    reg done_reg, done_next;

    assign tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    // state & output register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state        <= IDLE;
            tx_reg         <= 1;
            bit_count_reg  <= 0;
            data_reg       <= 8'h00;
            busy_reg       <= 1'b0;
            done_reg       <= 1'b0;
            tick_count_reg <= 4'h0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            bit_count_reg  <= bit_count_next;
            data_reg       <= data_next;
            busy_reg       <= busy_next;
            done_reg       <= done_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // next state & output CL
    always @(*) begin
        tx_next = tx_reg;
        n_state = c_state;
        bit_count_next = bit_count_reg;
        data_next = data_reg;
        done_next = done_reg;
        busy_next = busy_reg;
        tick_count_next = tick_count_reg;
        case (c_state)
            IDLE: begin
                // idle일 때는 done, busy 모두 0
                done_next = 1'b0;
                busy_next = 1'b0;
                tx_next   = 1'b1;
                if (tx_start) begin
                    // start 신호 받고 다음 clk (상태 변경과 동시에) busy 1로 변경
                    busy_next = 1'b1;
                    // tick count 초기화하고 상태 전이
                    tick_count_next = 0;

                    n_state = START;
                    // data를 레지스터에 저장하고 start로 감
                    data_next = tx_data;
                end
            end
            // WAIT: begin  // tx_start는 도착, baud_tick 대기
            //     tx_next = 1'b1;
            //     if (i_baud_tick)
            //         n_state = START;  // baud_tick 도착하면 start
            // end
            START: begin
                tx_next = 1'b0;
                bit_count_next = 3'b0;
                if (i_baud_tick) begin
                    if (tick_count_reg >= 15) begin
                        tick_count_next = 0;
                        n_state = DATA;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            DATA: begin
                if (i_baud_tick) begin
                    if (tick_count_reg == 0) begin
                        // tx_data 말고 저장된 data_reg 사용
                        // shift 방식으로 PISO 구현 -> LSB부터 전송
                        tx_next   = data_reg[0];
                        data_next = {1'b0, data_reg[7:1]};
                        // data_next = data_reg >> 1; // 논리 bit shift (부호확장x)
                    end

                    if (tick_count_reg >= 15) begin
                        tick_count_next = 0;
                        if (bit_count_reg >= 7) begin
                            // 전송 완료 -> STOP으로
                            n_state = STOP;
                        end else begin
                            // data의 다음 bit 전송
                            n_state = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (i_baud_tick) begin
                    if (tick_count_reg >= 15) begin
                        // stop 끝남과 동시에 busy도 0
                        busy_next = 1'b0;
                        // stop 끝남과 동시에 done이 1
                        done_next = 1'b1;
                        n_state   = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module uart_tx_origin (
    input clk,
    input reset,
    input i_baud_tick,
    input tx_start,
    input [7:0] tx_data,
    output tx
);

    // state
    localparam [3:0] IDLE = 4'h0;
    localparam [3:0] START = 4'h1;
    localparam [3:0] BIT_0 = 4'h2;
    localparam [3:0] BIT_1 = 4'h3;
    localparam [3:0] BIT_2 = 4'h4;
    localparam [3:0] BIT_3 = 4'h5;
    localparam [3:0] BIT_4 = 4'h6;
    localparam [3:0] BIT_5 = 4'h7;
    localparam [3:0] BIT_6 = 4'h8;
    localparam [3:0] BIT_7 = 4'h9;
    localparam [3:0] STOP = 4'hA;

    reg [3:0] c_state, n_state;
    reg tx_next, tx_reg;

    assign tx = tx_reg;

    // state & output register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            tx_reg  <= 1'b1;
        end else begin
            c_state <= n_state;
            tx_reg  <= tx_next;
        end
    end

    // next state & output CL
    always @(*) begin

        n_state = c_state;
        tx_next = tx_reg;
        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) n_state = START;
            end
            START: begin
                tx_next = 1'b0;
                if (i_baud_tick) n_state = BIT_0;
            end

            BIT_0: begin
                tx_next = tx_data[0];
                if (i_baud_tick) n_state = BIT_1;
            end

            BIT_1: begin
                tx_next = tx_data[1];
                if (i_baud_tick) n_state = BIT_2;
            end

            BIT_2: begin
                tx_next = tx_data[2];
                if (i_baud_tick) n_state = BIT_3;
            end

            BIT_3: begin
                tx_next = tx_data[3];
                if (i_baud_tick) n_state = BIT_4;
            end

            BIT_4: begin
                tx_next = tx_data[4];
                if (i_baud_tick) n_state = BIT_5;
            end

            BIT_5: begin
                tx_next = tx_data[5];
                if (i_baud_tick) n_state = BIT_6;
            end

            BIT_6: begin
                tx_next = tx_data[6];
                if (i_baud_tick) n_state = BIT_7;
            end

            BIT_7: begin
                tx_next = tx_data[7];
                if (i_baud_tick) n_state = STOP;
            end
            STOP: begin
                tx_next = 1'b1;
                if (i_baud_tick) n_state = IDLE;
            end
        endcase
    end
endmodule

// 9600bps (900hz) baud tick gen
module baud_tick_x16 (
    input  clk,
    input  reset,
    output o_baud_tick
);
    // 10416번 clk -> 1 tick
    // 100Mhz / 9600hz
    parameter F_COUNT = 100_000_000 / (9600 * 16);  // 주기가 16배 빨라짐
    reg  [$clog2(F_COUNT)-1:0] counter_reg;

    // CL로 할 수 있는 로직은 CL로 빼버린 방식
    wire [$clog2(F_COUNT)-1:0] counter_next;  // always면 reg여야 함

    // counter_reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // counter next CL
    assign counter_next = (counter_reg == F_COUNT - 1) ? 0 : counter_reg + 1;

    // always @(*) begin
    //     counter_next = counter_reg + 1;
    //     if (counter_reg == F_COUNT - 1) counter_next = 0;
    // end

    // output CL
    assign o_baud_tick  = (counter_reg == F_COUNT - 1) ? 1 : 0;

endmodule

// 9600bps (900hz) baud tick gen
module baud_tick (
    input  clk,
    input  reset,
    output o_baud_tick
);
    // 10416번 clk -> 1 tick
    // 100Mhz / 9600hz
    parameter F_COUNT = 10_416;
    reg  [$clog2(F_COUNT)-1:0] counter_reg;

    // CL로 할 수 있는 로직은 CL로 빼버린 방식
    wire [$clog2(F_COUNT)-1:0] counter_next;  // always면 reg여야 함

    // counter_reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // counter next CL
    assign counter_next = (counter_reg == F_COUNT - 1) ? 0 : counter_reg + 1;

    // always @(*) begin
    //     counter_next = counter_reg + 1;
    //     if (counter_reg == F_COUNT - 1) counter_next = 0;
    // end

    // output CL
    assign o_baud_tick  = (counter_reg == F_COUNT - 1) ? 1 : 0;

endmodule

module baud_tick_origin (
    input clk,
    input reset,
    output reg o_baud_tick
);
    // 10416번 clk -> 1 tick
    // 100Mhz / 9600hz
    parameter F_COUNT = 10_416;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_baud_tick <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_baud_tick <= 1;
            end else begin
                o_baud_tick <= 0;
            end
        end
    end

endmodule

