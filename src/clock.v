`timescale 1ns / 1ps


module clock #(
    parameter integer TICK_COUNT = 1_000_000
) (
    input clk,
    input reset,
    input btn_up,
    input btn_down,
    input btn_right,
    input btn_left,

    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    output [2:0] dot_op
);
    wire [2:0] w_cnt_8;
    wire w_inc_sec_1, w_inc_sec_10, w_inc_min_1, w_inc_min_10, w_inc_hour_1, w_inc_hour_10;
    wire w_dec_sec_1, w_dec_sec_10, w_dec_min_1, w_dec_min_10, w_dec_hour_1, w_dec_hour_10;

    clock_datapath #(
        .TICK_COUNT(TICK_COUNT)
    ) U_CLOCK_DATAPATH(
        .clk(clk),
        .reset(reset),
        .inc_sec_1(w_inc_sec_1),    
        .inc_sec_10(w_inc_sec_10),   
        .inc_min_1(w_inc_min_1),   
        .inc_min_10(w_inc_min_10),   
        .inc_hour_1(w_inc_hour_1),   
        .inc_hour_10(w_inc_hour_10),  
        .dec_sec_1(w_dec_sec_1),
        .dec_sec_10(w_dec_sec_10),
        .dec_min_1(w_dec_min_1),
        .dec_min_10(w_dec_min_10),
        .dec_hour_1(w_dec_hour_1),
        .dec_hour_10(w_dec_hour_10),

        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    time_change U_TIME_CHANGE(
        .btn_up(btn_up),
        .btn_down(btn_down),
        .cnt_8(w_cnt_8),        // cnt_8의 3비트를 다 넣는다.

        // 1의 자리와 10의 자리를 분리하여 출력
        .inc_sec_1(w_inc_sec_1),    
        .inc_sec_10(w_inc_sec_10),   
        .inc_min_1(w_inc_min_1),   
        .inc_min_10(w_inc_min_10),   
        .inc_hour_1(w_inc_hour_1),   
        .inc_hour_10(w_inc_hour_10),  
        .dec_sec_1(w_dec_sec_1),
        .dec_sec_10(w_dec_sec_10),
        .dec_min_1(w_dec_min_1),
        .dec_min_10(w_dec_min_10),
        .dec_hour_1(w_dec_hour_1),
        .dec_hour_10(w_dec_hour_10)
    );

    counter_8 U_COUNTER_8(
        .clk(clk),
        .reset(reset),
        .btn_right(btn_right),
        .btn_left(btn_left),
        .cnt_8(w_cnt_8)
    );

    assign dot_op = w_cnt_8;

endmodule

// ******************** time_change ************************
module time_change(
    input btn_up,
    input btn_down,
    input [2:0] cnt_8,

    // 1의 자리와 10의 자리를 분리하여 출력
    output reg inc_sec_1,    
    output reg dec_sec_1,
    output reg inc_sec_10,   
    output reg dec_sec_10,
    output reg inc_min_1,   
    output reg dec_min_1,
    output reg inc_min_10,   
    output reg dec_min_10,
    output reg inc_hour_1,   
    output reg dec_hour_1,
    output reg inc_hour_10,  
    output reg dec_hour_10
);


    wire [1:0] up_down;
    assign up_down = {btn_up, btn_down};

    always @(*) begin
        // 모든 출력 초기화 (래치 방지)
        inc_sec_1 = 0; dec_sec_1 = 0; inc_sec_10 = 0; dec_sec_10 = 0;
        inc_min_1 = 0; dec_min_1 = 0; inc_min_10 = 0; dec_min_10 = 0;
        inc_hour_1 = 0; dec_hour_1 = 0; inc_hour_10 = 0; dec_hour_10 = 0;

        case (cnt_8) 

            3'b010 : begin
                if (up_down == 2'b10) inc_sec_1 = 1;
                else if (up_down == 2'b01) dec_sec_1 = 1;
            end

            3'b011 : begin
                if (up_down == 2'b10) inc_sec_10 = 1;
                else if (up_down == 2'b01) dec_sec_10 = 1;
            end          

            3'b100 : begin
                if (up_down == 2'b10) inc_min_1 = 1;
                else if (up_down == 2'b01) dec_min_1 = 1;
            end     

            3'b101 : begin
                if (up_down == 2'b10) inc_min_10 = 1;
                else if (up_down == 2'b01) dec_min_10 = 1;
            end     

            3'b110 : begin
                if (up_down == 2'b10) inc_hour_1 = 1;
                else if (up_down == 2'b01) dec_hour_1 = 1;
            end     

            3'b111 : begin
                if (up_down == 2'b10) inc_hour_10 = 1;
                else if (up_down == 2'b01) dec_hour_10 = 1;
            end     

        endcase
    end
    

endmodule


// ******************** counter_8 ************************
module counter_8 (
    input clk,
    input reset,
    input btn_right,
    input btn_left,

    output reg [2:0] cnt_8
);

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            cnt_8 <= 3'b110;
        end

        else if (btn_left) begin     
            cnt_8 <= cnt_8 + 1;
        end

        else if (btn_right) begin
            cnt_8 <= cnt_8 -1;
        end
    end



endmodule


// *******************clock_datapath*****************************
// clock_datapath (Sub-module) (instance 수정)
module clock_datapath #(
                                // 디지털 시계나 스톱워치에서 소수점 두 자리로 표현되는 숫자는 1ms 단위가 아니라 10ms단위 -> 7초42 = 7초 420ms
    parameter MSEC_WIDTH = 7,   // 100를 표현하려면 최소 7비트 필요
    SEC_WIDTH = 6,              // 60을 표현하려면 최소 6비트 필요
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    TICK_COUNT = 1_000_000
) (
    input                     clk,
    input                     reset,
    input                     inc_sec_1,
    input                     inc_sec_10,
    input                     inc_min_1,
    input                     inc_min_10,
    input                     inc_hour_1,
    input                     inc_hour_10,
    input                     dec_sec_1,
    input                     dec_sec_10,
    input                     dec_min_1,
    input                     dec_min_10,
    input                     dec_hour_1,
    input                     dec_hour_10,
    output [MSEC_WIDTH-1 : 0] msec,
    output [ SEC_WIDTH-1 : 0] sec,
    output [ MIN_WIDTH-1 : 0] min,
    output [HOUR_WIDTH-1 : 0] hour
);
    wire w_tick_100hz, w_tick_sec, w_tick_min, w_tick_hour;

    // Hour
    clock_time_counter #(
        .BIT_WIDTH(HOUR_WIDTH),
        .TIMES(24),
        .INIT_VALUE(12)
    ) U_HOUR_COUNTER (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_tick_hour),
        .manual_dec_1(dec_hour_1),
        .manual_dec_10(dec_hour_10),
        .manual_inc_1(inc_hour_1),
        .manual_inc_10(inc_hour_10),
        .time_count(hour),
        .o_tick    ()              // 해당 핀은 연결 x
    );

    // min
    clock_time_counter #(
        .BIT_WIDTH(MIN_WIDTH),
        .TIMES(60),
        .INIT_VALUE(0)
    ) U_MIN_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        .manual_dec_1(dec_min_1),
        .manual_dec_10(dec_min_10),
        .manual_inc_1(inc_min_1),
        .manual_inc_10(inc_min_10),
        .time_count(min),
        .o_tick(w_tick_hour)
    );

    // Sec
    clock_time_counter #(
        .BIT_WIDTH(SEC_WIDTH),
        .TIMES(60),
        .INIT_VALUE(0)
    ) U_SEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        .manual_dec_1(dec_sec_1),
        .manual_dec_10(dec_sec_10),
        .manual_inc_1(inc_sec_1),
        .manual_inc_10(inc_sec_10),
        .time_count(sec),
        .o_tick(w_tick_min)
    );

    // msec
    clock_time_counter #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES(100),
        .INIT_VALUE(0)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .manual_dec_1(1'b0), // 0을 확실히 넣어줌
        .manual_dec_10(1'b0),
        .manual_inc_1(1'b0),
        .manual_inc_10(1'b0),
        .time_count(msec),
        .o_tick(w_tick_sec)
    );

    clock_tick_gen_100hz  #(
        .F_COUNT(TICK_COUNT)
    )U_TICK_GEN_100Hz(
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_100hz)
    );

    // parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;
endmodule




// TICK_GEN module
module clock_tick_gen_100hz (
    input      clk,
    input      reset,
    output reg o_tick
);

    parameter F_COUNT = 1_000_000;  // 1_000_000 (빠르게 시뮬에선 1_000 -> 100KHz Tick_gen)
    reg [$clog2(F_COUNT) - 1 : 0] counter_reg;

    always @(posedge clk, posedge reset) begin

        if (reset) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule


// ********************************** time_counter (모듈 수정) **********************************
// time_counter
module clock_time_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    INIT_VALUE = 0
) (
    input                        clk,
    input                        reset,
    input                        i_tick,
    input                        manual_dec_1, manual_dec_10,    // 새로 추가된 수동 감소 신호
    input                        manual_inc_1, manual_inc_10,    // 새로 추가된 수동 증가 신호
    output     [BIT_WIDTH-1 : 0] time_count,
    output reg                   o_tick
);

    reg [$clog2(TIMES) -1 : 0] counter_reg;

    assign time_count = counter_reg;

    always @(posedge clk, posedge reset) begin // <---------------------------- 문제 (edge case 고려 X) hour는 12시 모드, 24시 모드도 있음 -> 24시 모드만 고려하기로 함


        if (reset) begin
            counter_reg <= INIT_VALUE;
            o_tick      <= 1'b0;
        end 
        /* old
        // 1. 수동 조작(10의 자리) (버튼 입력)이 들어왔을 때 우선 처리
        else if (manual_inc_10) begin
            // ex) 53초에서 10을 더하면 63이 아니라 03이 되어야 함 (TIMES=60일 때 50을 빼줌)
            // 15시에서 10 더할 경우 15 >= (24-10) 이라 1이
            if (counter_reg >= (TIMES - 10)) counter_reg <= counter_reg - (TIMES - 10);
            else counter_reg <= counter_reg + 10;
            o_tick <= 1'b0;
        end
        */
        // new
        else if (manual_inc_10) begin
            // 10을 더했을 때 최대치(TIMES)를 넘어가면
            // 10의 자리는 0으로 롤오버하고 1의 자리(% 10)만 남김
            if (counter_reg + 10 >= TIMES) 
                counter_reg <= counter_reg % 10;
            else 
                counter_reg <= counter_reg + 10;
                
            o_tick <= 1'b0;
        end

        /* old
        else if (manual_dec_10) begin
            // ex) 03에서 -> 10 감소 = 53 = TIMES - (10-03)
            if (counter_reg < 10) counter_reg <= counter_reg + (TIMES - 10);        // (TIMES) -(10 - counter_reg);
            else counter_reg <= counter_reg - 10;
            o_tick <= 1'b0;
        end
        */
        // new
        else if (manual_dec_10) begin
            // 10을 뺄 때 0보다 작아지면 (현재 10 미만이면)
            // 1의 자리를 유지하면서 가질 수 있는 TIMES 미만의 가장 큰 값으로 롤오버
            if (counter_reg < 10) 
                counter_reg <= counter_reg + ((TIMES - 1 - counter_reg) / 10) * 10;
            else 
                counter_reg <= counter_reg - 10;
                
            o_tick <= 1'b0;
        end

        // 2. 수동 조작(1의 자리) (버튼 입력)이 들어왔을 때 우선 처리
        else if (manual_inc_1) begin
            if (counter_reg == (TIMES - 1)) counter_reg <= 0;
            else counter_reg <= counter_reg + 1;
            o_tick <= 1'b0;
        end

        else if (manual_dec_1) begin
            if (counter_reg == 0) counter_reg <= (TIMES -1);
            else counter_reg <= counter_reg - 1;
            o_tick <= 1'b0;
        end

        // 3. 수동 조작 없을 때 정상적인 시계 동작
        else if(i_tick) begin

            if (counter_reg == (TIMES - 1)) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;
            end 
            else begin
                counter_reg <= counter_reg + 1;
                o_tick      <= 1'b0;
            end
        end
        else o_tick <= 1'b0;
         
    end
endmodule
