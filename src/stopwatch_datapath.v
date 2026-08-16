`timescale 1ns / 1ps

module top_stopwatch (
    input clk,
    input reset,
    input rx,
    input btn_L,  // runstop(s) / 자리변경(w) 
    input btn_R,  // clear(s) / 자리변경(w)
    input btn_UP,  // mode(s) / up(w)
    input btn_DOWN,  // option(s) / down(w)
    input  [2:0] sw,        // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch, sw[2] : watch의 12시간제
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output led,  // indicator
    output tx
);

    // rx로 pc에서 받은 데이터
    wire [7:0] w_rx_data;
    // // 데이터 저장할 reg
    // reg [7:0] w_rw_data_reg;
    // rx에서 데이터 모두 받으면 1clk 동안 1
    wire w_rx_done;

    // signal decoding에서 rw_done 활용하려면 f/f에 의한 1clk 지연 발생하면 안됨
    // // rw done일 때만 reg에 rx 데이터를 저장 -> ascii decoding에 사용
    // always @(posedge clk, posedge reset) begin
    //     if (reset)begin
    //         w_rw_data_reg <= 0;
    //     end else begin
    //         if (w_rw_done) w_rw_data_reg <= w_rw_data;
    //     end
    // end

    // 1 clk 펄스 신호로 변환
    wire w_ascii_run, w_ascii_stop, w_ascii_clear, w_ascii_mode, w_ascii_up, w_ascii_down, w_ascii_left, w_ascii_right, w_ascii_save, w_ascii_load;
    // rx로 받은 ascii 디코딩 -> one hot encoded
    wire [9:0] w_ascii_decoded;

    // one hot encoded signal -> 1 clk 펄스 신호로 변환
    assign {w_ascii_run, w_ascii_stop, w_ascii_clear, w_ascii_mode, w_ascii_up, w_ascii_down, w_ascii_left, w_ascii_right, w_ascii_save, w_ascii_load} = w_ascii_decoded & {10{w_rx_done}};

    // btn debounder OUTPUT SIGNAL
    wire w_btn_L, w_btn_R, w_btn_UP, w_btn_DOWN;

    // control unit -> datapath
    wire w_runstop, w_clear, w_mode, w_save, w_load;
    wire w_is_data_saved;

    // 값 저장 상태를 출력
    assign led = w_is_data_saved;

    wire [1:0] w_state;
    wire [1:0] w_fnd_state;

    // 결정된 시간 데이터
    wire [6:0] w_msec;
    wire [5:0] w_sec, w_min;
    wire [4:0] w_hour;

    // stopwatch의 시간 데이터
    wire [6:0] w_msec_stopwatch;
    wire [5:0] w_sec_stopwatch, w_min_stopwatch;
    wire [4:0] w_hour_stopwatch;

    // watch의 시간 데이터
    wire [6:0] w_msec_watch;
    wire [5:0] w_sec_watch, w_min_watch;
    wire [4:0] w_hour_watch;

    // watch의 12시간제
    wire w_format12_watch;
    reg [4:0] w_hour_display_watch;
    assign w_format12_watch = sw[2];

    always @(*) begin
        w_hour_display_watch = w_hour_watch; //sw[2] = 0이면 원래 24시간제
        if (w_format12_watch) begin  //12시간제 스위치 키면
            if (w_hour_watch > 12)
                w_hour_display_watch = w_hour_watch - 12;  //13~23을 1~11로
            else if (w_hour_watch == 0)
                w_hour_display_watch = 12;  //00시를 12시로
        end
    end

    assign w_msec = (sw[1]) ? w_msec_watch : w_msec_stopwatch;
    assign w_sec = (sw[1]) ? w_sec_watch : w_sec_stopwatch;
    assign w_min = (sw[1]) ? w_min_watch : w_min_stopwatch;

    // watch일 땐 12시간제, stopwatch는 w_hour_stopwatch로
    assign w_hour = (sw[1]) ? w_hour_display_watch : w_hour_stopwatch;

    assign w_fnd_state = (sw[1]) ? w_state : 2'b00;

    btn_debouncer U_DB_BTN_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debouncer U_DB_BTN_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debouncer U_DB_BTN_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_UP),
        .o_btn(w_btn_UP)
    );

    btn_debouncer U_DB_BTN_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_DOWN),
        .o_btn(w_btn_DOWN)
    );


    uart_loop_back U_LOOP_BACK (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    ascii_decoder U_ASCII_DECODER (
        .i_data(w_rx_data),
        .o_signals(w_ascii_decoded)
        // .run(),
        // .stop(),
        // .clear(),
        // .mode(),
        // .up(),
        // .down(),
        // .left(),
        // .right()
    );

    // todo: 디코딩된 signal들을 1 clk pulse로 변경 -> 완료
    // todo: 1 clk pulse된 signal들 or로 control unit 연결 -> 완료
    // todo: run/stop 나뉘어있는 rx signal을 control unit에서 통합 -> 완료

    // stopwatch control unit
    control_unit U_CNTL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_runstop(w_btn_L & !sw[1]),
        .i_ascii_run(w_ascii_run),  // stop일 때 run 가능
        .i_ascii_stop(w_ascii_stop),  // run일 때 stop 가능
        .i_clear((w_ascii_clear | w_btn_R) & !sw[1]),
        .i_mode((w_ascii_mode | w_btn_UP) & !sw[1]),
        .i_save_load(w_btn_DOWN & !sw[1]),  // btn down
        .i_ascii_save(w_ascii_save), // 데이터 존재하지 않으면 save
        .i_ascii_load(w_ascii_load), // 데이터 존재하면 load
        .i_is_data_saved(w_is_data_saved), // datapath에 데이터 저장되어 있는지 t/f 
        .o_runstop(w_runstop),
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_save(w_save),
        .o_load(w_load)
    );


    // stopwatch datapath
    stopwatch_datapath U_DATAPATH (
        .clk            (clk),
        .reset          (reset),
        .runstop        (w_runstop),
        .clear          (w_clear),
        .mode           (w_mode),
        .save           (w_save),
        .load           (w_load),
        .o_is_data_saved(w_is_data_saved),
        .m_sec          (w_msec_stopwatch),
        .sec            (w_sec_stopwatch),
        .min            (w_min_stopwatch),
        .hour           (w_hour_stopwatch)
    );

    // watch control unit
    watch_control_unit U_CNTL_UNIT_WATCH (
        .clk  (clk),
        .reset(reset),
        .btn_L((w_ascii_left | w_btn_L) & sw[1]),
        .btn_R((w_ascii_right | w_btn_R) & sw[1]),
        .state(w_state)
    );

    // watch datapath
    watch_datapath U_DATAPATH_WATCH (
        .clk  (clk),
        .reset(reset),
        .up   ((w_ascii_up | w_btn_UP) & sw[1]),
        .down ((w_ascii_down | w_btn_DOWN) & sw[1]),
        .state(w_state),
        .msec(w_msec_watch),
        .sec  (w_sec_watch),
        .min  (w_min_watch),
        .hour (w_hour_watch)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .reset(reset),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .state(w_fnd_state),
        .sw(sw[1:0]),
        .display_mode(sw[0]),  // sw[0] -> 0=초/1=시간 선택
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

endmodule

module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                       clk,
    input                       reset,
    input                       runstop,
    input                       clear,
    input                       mode,
    input                       save,
    input                       load,
    output reg                  o_is_data_saved,
    output     [MSEC_WIDTH-1:0] m_sec,
    output     [ SEC_WIDTH-1:0] sec,
    output     [ MIN_WIDTH-1:0] min,
    output     [HOUR_WIDTH-1:0] hour
);

    wire w_tick_msec, w_tick_sec, w_tick_min, w_tick_hour;

    // f/f에 저장된 시간 데이터
    reg [MSEC_WIDTH-1:0] w_saved_msec;
    reg [ SEC_WIDTH-1:0] w_saved_sec;
    reg [ MIN_WIDTH-1:0] w_saved_min;
    reg [HOUR_WIDTH-1:0] w_saved_hour;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            w_saved_msec <= 0;
            w_saved_sec <= 0;
            w_saved_min <= 0;
            w_saved_hour <= 0;
            o_is_data_saved <= 0;
        end else begin
            if (save) begin
                w_saved_msec <= m_sec;
                w_saved_sec <= sec;
                w_saved_min <= min;
                w_saved_hour <= hour;
                o_is_data_saved <= 1;
            end
            if (load) begin
                o_is_data_saved <= 0;
            end
        end
    end

    tick_gen_100hz GEN_100HZ (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_msec)
    );

    time_counter #(
        .COUNT_NUM(100)
    ) U_COUNTER_MSEC (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_msec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_msec),
        .time_cnt(m_sec),
        .o_tick(w_tick_sec)
    );

    time_counter #(
        .COUNT_NUM(60)
    ) U_COUNTER_SEC (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_sec),
        .time_cnt(sec),
        .o_tick(w_tick_min)
    );

    time_counter #(
        .COUNT_NUM(60)
    ) U_COUNTER_MIN (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_min),
        .time_cnt(min),
        .o_tick(w_tick_hour)
    );

    time_counter #(
        .COUNT_NUM(24)
    ) U_COUNTER_HOUR (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_hour),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_hour),
        .time_cnt(hour),
        .o_tick()
    );

endmodule

module time_counter #(
    parameter COUNT_NUM = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input run_stop,
    input clear,
    input load,
    input [$clog2(COUNT_NUM)-1:0] value,
    output reg [$clog2(COUNT_NUM)-1:0] time_cnt,
    output reg o_tick
);

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            time_cnt <= 0;
            o_tick   <= 1'b0;
        end else begin
            if (i_tick & run_stop) begin
                if (!mode) begin
                    time_cnt <= time_cnt + 1;
                    if (time_cnt == COUNT_NUM - 1) begin
                        time_cnt <= 0;
                        o_tick   <= 1'b1;
                    end
                end else begin
                    time_cnt <= time_cnt - 1;
                    if (time_cnt == 0) begin
                        time_cnt <= COUNT_NUM - 1;
                        o_tick   <= 1'b1;
                    end
                end
            end else begin
                o_tick <= 1'b0;
            end
            if (load) time_cnt <= value;
        end
    end

endmodule


module tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);

    parameter F_COUNT = 1_000_000;
    //parameter F_COUNT = 1000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick <= 1'b0;
            end
        end
    end

endmodule

