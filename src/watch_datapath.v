`timescale 1ns / 1ps

module watch_datapath (
    input        clk,
    input        reset,
    input        up,
    input        down,
    input  [1:0] state,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire o_tick_msec, o_tick_sec, o_tick_min, o_tick_hour;
    wire w_up_sec, w_up_min, w_up_hour;
    wire w_down_sec, w_down_min, w_down_hour;

    tick_gen_100hz U_TICK_GEN (
        .clk(clk),
        .reset(reset),
        .o_tick(o_tick_msec)
    );

    demux_1x3 U_DMUX_UP (
        .sel  (state),
        .i_btn(up),
        .o_btn({w_up_hour, w_up_min, w_up_sec})
    );

    demux_1x3 U_DMUX_DOWN (
        .sel  (state),
        .i_btn(down),
        .o_btn({w_down_hour, w_down_min, w_down_sec})
    );

    watch_time_counter #(
        .COUNT_NUM(100)
    ) U_WATCH_COUNTER_MSEC (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick_msec),
        .i_up(1'b0),
        .i_down(1'b0),
        .time_cnt(msec),
        .o_tick(o_tick_sec)
    );

    watch_time_counter #(
        .COUNT_NUM(60)
    ) U_WATCH_COUNTER_SEC (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick_sec),
        .i_up(w_up_sec),
        .i_down(w_down_sec),
        .time_cnt(sec),
        .o_tick(o_tick_min)
    );

    watch_time_counter #(
        .COUNT_NUM(60)
    ) U_WATCH_COUNTER_MIN (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick_min),
        .i_up(w_up_min),
        .i_down(w_down_min),
        .time_cnt(min),
        .o_tick(o_tick_hour)
    );

    watch_time_counter #(
        .COUNT_NUM(24),
        .INIT_NUM (12)
    ) U_WATCH_COUNTER_HOUR (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick_hour),
        .i_up(w_up_hour),
        .i_down(w_down_hour),
        .time_cnt(hour),
        .o_tick()
    );


endmodule

module demux_1x3 (
    input [1:0] sel,
    input i_btn,
    output reg [2:0] o_btn
);

    always @(*) begin
        case (sel)
            2'b00: o_btn = 3'b000;  // start = 모두 선택 안됨
            2'b01: o_btn = {{i_btn}, 2'b00};  // hour = 시간 변경
            2'b10: o_btn = {1'b0, {i_btn}, 1'b0};  // min = 분 변경
            2'b11: o_btn = {2'b00, {i_btn}};  // sec = 초 변경
        endcase
    end

endmodule

module watch_time_counter #(
    parameter COUNT_NUM = 100,
    INIT_NUM = 0
) (
    input                              clk,
    input                              reset,
    input                              i_tick,
    input                              i_up,
    input                              i_down,
    output reg [$clog2(COUNT_NUM)-1:0] time_cnt,
    output reg                         o_tick
);

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            time_cnt <= INIT_NUM;
            o_tick   <= 1'b0;
        end else begin
            if (i_tick) begin
                time_cnt <= time_cnt + 1;
                if (time_cnt == COUNT_NUM - 1) begin
                    time_cnt <= 0;
                    o_tick   <= 1'b1;
                end
            end else begin
                o_tick <= 1'b0;
            end
            if (i_up) begin
                time_cnt <= time_cnt + 1;
                if (time_cnt == COUNT_NUM - 1) time_cnt <= 0;
            end
            if (i_down) begin
                time_cnt <= time_cnt - 1;
                if (time_cnt == 0) time_cnt <= COUNT_NUM - 1;
            end
        end
    end

endmodule
