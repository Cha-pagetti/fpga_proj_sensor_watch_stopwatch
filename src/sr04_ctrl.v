`timescale 1ns / 1ps

module sr04_ctrl (
    input               clk,
    input               reset,
    input               start,      // start를 BTN 입력으로 받는다
    input               echo,       // 왜 동기화가 필요할까??
    output reg          trigger,    // 측정 시작 요청 신호
    output reg          done,         
    output    [8:0] distance    // 400cm 표현 -> 9비트 필요
);

    wire w_tick_us;

    // FSM controller (control unit)
    localparam [2:0] IDLE = 0, START = 1, WAIT = 2, COUNT = 3, DISTANCE = 4;
    reg [2:0] c_state, n_state;
    reg run_stop;       
    reg clear;
    // Echo HIGH 시간을 1us 단위로 측정
    // reg [$clog2(58*400)-1: 0] counter_reg, counter_next; // 400cm 표현 -> 1cm 당 58us 필요 -> 400 * 58 tick 필요
    reg [$clog2(50_000)-1: 0] counter_reg, counter_next; // 400cm 표현 -> 1cm 당 58us 필요 -> 400 * 58 tick 필요

    reg echo_reg, echo_next;
    reg [8:0] distance_reg, distance_next;

    tick_us U_TICK_US (
        .clk      (clk),
        .reset    (reset),
        .run_stop (run_stop),   
        .clear    (clear),
        .o_tick_us(w_tick_us)
    );

    ila_0 U_ILA (
        .clk   (clk),
        .probe0(start),     // start
        .probe1(trigger),   // trigger
        .probe2(echo),      // echo
        .probe3(c_state)    // state
    );   

    assign distance = distance_reg;

    // State + SL 출력 (echo 및 counter_reg)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            counter_reg <= 0;
            echo_reg <= 0;
            distance_reg <= 0;
        end
        else begin
            c_state <= n_state;
            counter_reg <= counter_next;
            echo_reg <= echo_next;
            distance_reg <= distance_next;
        end
    end



    // Next, output (이건 조합 출력(Output))
    always @(*) begin
        // Init
        n_state  = c_state;
        counter_next = counter_reg;
        run_stop = 1'b0;
        clear    = 1'b0;
        trigger  = 1'b0;
        done     = 1'b0;
        echo_next= 1'b0;
        distance_next = distance_reg;
        // distance = 1'b0;
        

        case (c_state)
            IDLE: begin
                run_stop = 1'b0;
                clear    = 1'b1;
                done     = 1'b0;
                // distance = 0;
                if (start) begin            // start는 pulse 신호
                    n_state      = START;
                    counter_next = 0;
                end
            end

            // Trigger 생성해야 됨 (trigger 이후 8cycle 후 echo 신호 올 때까지 대기)
            START: begin
                run_stop = 1'b1;  // always 구문이니 출력은 reg // 계속 1이어야 tick 돌아감
                clear    = 1'b0;
                trigger  = 1'b1;
                distance_next = 0;

                if(w_tick_us) begin
                    counter_next = counter_reg + 1;
                end
                if (counter_reg == 11) begin
                    n_state = WAIT;
                    counter_next = 0;
                end
            end

            WAIT : begin            // 8cycle은 SR04 내부에서 일어나는 것 ctrl로 제어하는 것이 X
                run_stop = 1'b1;
                trigger   = 1'b0;

                if (echo) begin
                    n_state = COUNT;
                end
            end

            COUNT: begin
                run_stop = 1'b1;
                if (echo) begin
                    if(w_tick_us) begin
                        counter_next = counter_reg + 1;
                    end
                end
                else begin  // echo = 0 (LOW로 떨어질 때)
                    n_state = DISTANCE;
                    // 방어 로직
                    // if (counter_reg >= 5000) begin
                    if (counter_reg >= 20_000) begin

                        distance_next = 0;
                    end
                    else begin
                        distance_next = counter_reg / 58;        // 나누기 연산 -> 1cycle로 하면 Negative Slack 나올 수 있다.
                    end
                    counter_next = 0;
                    trigger = 1'b0;
                end
            end

            // 수신부 에코 쪽에 Synchronizer
            // 다음 Trigger와 echo가 LOW 간격은 10ms 이므로 -> 1us tick으로 10_000 count
            DISTANCE : begin
                run_stop= 1;

                if(w_tick_us) begin
                    counter_next = counter_reg + 1;
                    // 10ms delay = tick_us * 10_000
                    if(counter_next == 9_999) begin 
                        n_state = IDLE;
                        counter_next = 0;
                        trigger = 1'b0;
                        done = 1'b1;
                    end
                end
            end
        endcase
    end

endmodule




// 교수님 모듈
// tick_gen을 run_stop으로 제어하는 방법 배움
module tick_us (
    input  clk,
    input  reset,
    input  run_stop,
    input  clear,
    output o_tick_us
);

    parameter F_COUNT = 100;

    reg [$clog2(F_COUNT) -1:0] counter_reg;
    reg tick_us_reg;

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end
        else begin
            if (run_stop) begin
                counter_reg <= counter_reg + 1;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg <= 0;
                    tick_us_reg <= 1;
                end
                else begin
                    tick_us_reg <= 0;
                end
            end
        end
    end

    assign o_tick_us = tick_us_reg;



endmodule






// *********************************** My module *******************************************


// ************************************* sr04_ctrl *****************************************
// // 내가 설계한 모듈
// module sr04_ctrl (
//     input        clk,
//     input        reset,
//     input        start,
//     input        echo,
//     output       trigger,
//     output       done,
//     output [8:0] distance  // 400cm 표현 -> 9비트 필요
// );

//     wire w_start;
//     wire i_tick;

//     tick_us U_TICK_US (
//         .clk      (clk),
//         .reset    (reset),
//         .run_stop (w_start),
//         .clear    (),
//         .o_tick_us(i_tick)
//     );

//     parameter READY = 3'b000;
//     parameter START = 3'b001;
//     parameter WAIT = 3'b010;
//     parameter RECEIVE = 3'b011;
//     parameter DONE = 3'b100;

//     reg [2:0] n_state, c_state;
//     reg trigger_next, trigger_reg;
//     reg done_next, done_reg;
//     reg [8:0] distance_next, distance_reg;

//     reg [15:0]
//         tick_cnt_next,
//         tick_cnt_reg;  // 60_000을 표현하려면 16비트 필요
//     reg echo_next, echo_reg;

//     // state (SL)
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             c_state      <= READY;  // ***********************************
//             trigger_reg  <= 0;
//             done_reg     <= 0;
//             distance_reg <= 8'h00;
//             tick_cnt_reg <= 16'h0000;
//             // echo_reg     <= 0;
//         end
//         else begin
//             c_state      <= n_state;
//             trigger_reg  <= trigger_next;
//             done_reg     <= done_next;
//             distance_reg <= distance_next;
//             tick_cnt_reg <= tick_cnt_next;
//         end
//     end

//     // Next (CL)
//     always @(*) begin
//         n_state = c_state;
//         trigger_next = trigger_reg;
//         done_next = done_reg;
//         distance_next = distance_reg;

//         case (c_state)
//             READY: begin
//                 if (start == 1) begin
//                     n_state = START;
//                     trigger_next = 1;
//                 end
//                 else begin
//                     n_state = READY;
//                 end
//             end

//             START: begin
//                 if (i_tick) begin
//                     if (tick_cnt_reg == 10) begin
//                         n_state = WAIT;
//                         trigger_next = 0;
//                         tick_cnt_next = 0;
//                     end
//                     else begin
//                         tick_cnt_next = tick_cnt_reg + 1;
//                     end
//                 end
//                 else begin
//                     n_state = START;
//                 end
//             end

//             WAIT: begin
//                 if (echo_reg) begin
//                     n_state = RECEIVE;
//                 end
//                 else begin
//                     n_state = WAIT;
//                 end
//             end

//             RECEIVE: begin
//                 if (!echo) begin
//                     n_state = DONE;
//                     distance_next = tick_cnt_reg / 58;
//                     tick_cnt_next = 0;
//                     echo_next = 0;
//                 end
//                 else begin
//                     n_state   = RECEIVE;
//                     done_next = 1;
//                     if (i_tick) begin
//                         tick_cnt_next = tick_cnt_reg + 1;
//                     end
//                 end
//             end

//             DONE: begin
//                 n_state = READY;
//             end


//         endcase
//     end

//     // Output
//     assign distance = distance_reg;
//     assign trigger = trigger_reg;
//     assign done = done_reg;

// endmodule



// ************************************* tick_us *****************************************
// 1MHz tick_gen (period = 1us)
// module tick_us (
//     input  clk,
//     input  reset,
//     input  run_stop,
//     input  clear,
//     output o_tick_us
// );

//     parameter F_COUNT = 100_000_000 / 1_000_000;

//     reg [$clog2(F_COUNT)-1:0] cnt_reg;
//     reg                       o_tick_us_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             cnt_reg <= 0;
//             o_tick_us_reg <= 0;
//         end
//         else begin
//             if (cnt_reg == F_COUNT - 1) begin
//                 cnt_reg <= 0;
//                 o_tick_us_reg <= 1;
//             end
//             else begin
//                 cnt_reg <= cnt_reg + 1;
//                 o_tick_us_reg <= 0;
//             end
//         end
//     end

//     assign o_tick_us = o_tick_us_reg;


// endmodule


