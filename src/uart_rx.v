`timescale 1ns / 1ps


module uart_rx (
    input        clk,
    input        reset,
    input        i_baud_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA = 2'b10;
    localparam [1:0] STOP = 2'b11;

    reg [1:0] state_reg, state_next;
    reg [7:0] data_reg, data_next;

    reg [3:0] tick_count, tick_count_next;
    reg [2:0] bit_count, bit_count_next;

    reg rx_done_reg, rx_done_next;

    assign rx_data = data_reg;
    assign rx_done = rx_done_reg;

    // state reg
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg   <= IDLE;
            data_reg    <= 0;
            tick_count  <= 0;
            bit_count   <= 0;
            rx_done_reg <= 0;
        end else begin
            state_reg   <= state_next;
            data_reg    <= data_next;
            tick_count  <= tick_count_next;
            bit_count   <= bit_count_next;
            rx_done_reg <= rx_done_next;
        end

    end

    // next state CL
    always @(*) begin
        state_next = state_reg;
        data_next = data_reg;
        tick_count_next = tick_count;
        bit_count_next = bit_count;
        rx_done_next = rx_done_reg;
        case (state_reg)
            IDLE: begin
                rx_done_next   = 0;
                bit_count_next = 0;
                if (i_baud_tick) begin
                    if (!rx) begin
                        if (tick_count >= 7) begin
                            // tick 왔을때 rx 0이고 tick count 7이면
                            // 다음 state -> START로!
                            tick_count_next = 0;
                            state_next = START;
                        end else begin
                            // tick 왔을때 rx 0인데 tick count 7보다 작음
                            // tick count 한 번 더 세기
                            tick_count_next = tick_count + 1;
                        end
                    end else begin
                        // tick 왔을때 rx 1
                        // state idle임
                        tick_count_next = 0;
                        bit_count_next  = 0;
                        //data_next = 8'h00;
                    end
                end
            end
            START: begin
                if (i_baud_tick) begin
                    if (tick_count >= 15) begin
                        // tick 왔을 때 tick count 15면
                        // 다음 state -> DATA
                        tick_count_next = 4'h0;
                        state_next = DATA;
                    end else begin
                        // tick 왔을 때 tick count 15보다 작으면
                        // tick count 한 번 더 세기
                        tick_count_next = tick_count + 1;
                    end
                end
            end
            DATA: begin
                if (i_baud_tick) begin
                    // 처음 와서 tick count 0일 때 data_reg에 rx 저장
                    if (tick_count == 0) begin
                        // pipo, bit indexing 방식
                        // data_next[bit_count] = rx;

                        // sipo, bit shift 방식
                        // MSB 자리로 계속 넣어서 LSB 방향으로 밀어낸다
                        data_next = {rx, data_reg[7:1]};
                    end

                    if (tick_count >= 15) begin
                        tick_count_next = 0;
                        if (bit_count >= 7) begin
                            // tick 왔을 때 이미 bit 7번까지 다 넣었고 tick count 16번 셈
                            // 다음 state -> STOP
                            //tick_count_next = 4'h0;
                            state_next = STOP;
                        end else begin
                            // tick 왔을 때 tick count 16번 셌는데 아직 bit 7번 아님
                            // 다음 bit로 가자
                            //tick_count_next = 0;
                            bit_count_next = bit_count + 1;
                        end
                    end else begin
                        // tick 왔을 때 아직 tick count 16번 안셈
                        // tick count 한 번 더 세자
                        tick_count_next = tick_count + 1;
                    end
                end
            end
            STOP: begin
                if (i_baud_tick) begin
                    if (tick_count >= 0) begin
                        //tick 왔고 8번 셌음
                        //그럼 다음 state -> IDLE
                        tick_count_next = 4'h0;
                        bit_count_next = 3'b000;
                        //data_next = 8'h00;
                        state_next = IDLE;

                        // 다 끝났으니까 rx_done 띄우기
                        rx_done_next = 1'b1;
                    end
                    else begin
                        // tick 왔고 아직 8번 안 셌음
                        // 그럼 tick 한 번 더 세기
                        tick_count_next = tick_count + 1;
                    end
                end
            end
        endcase
    end

endmodule
