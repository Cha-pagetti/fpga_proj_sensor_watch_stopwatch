`timescale 1ns / 1ps

module stopwatch_datapath #(
    parameter integer TICK_COUNT = 1_000_000,
    parameter integer MSEC_WIDTH = 7,
    parameter integer SEC_WIDTH  = 6,
    parameter integer MIN_WIDTH  = 6,
    parameter integer HOUR_WIDTH = 5
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
    wire tick_msec;
    wire tick_sec;
    wire tick_min;
    wire tick_hour;

    reg [MSEC_WIDTH-1:0] saved_msec_reg;
    reg [SEC_WIDTH-1:0]  saved_sec_reg;
    reg [MIN_WIDTH-1:0]  saved_min_reg;
    reg [HOUR_WIDTH-1:0] saved_hour_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            saved_msec_reg  <= 0;
            saved_sec_reg   <= 0;
            saved_min_reg   <= 0;
            saved_hour_reg  <= 0;
            o_is_data_saved <= 1'b0;
        end else begin
            if (save) begin
                saved_msec_reg  <= m_sec;
                saved_sec_reg   <= sec;
                saved_min_reg   <= min;
                saved_hour_reg  <= hour;
                o_is_data_saved <= 1'b1;
            end else if (load) begin
                o_is_data_saved <= 1'b0;
            end
        end
    end

    stopwatch_tick_gen #(
        .F_COUNT(TICK_COUNT)
    ) U_STOPWATCH_TICK (
        .clk(clk),
        .reset(reset),
        .o_tick(tick_msec)
    );

    stopwatch_time_counter #(.COUNT_NUM(100)) U_MSEC (
        .clk(clk), .reset(reset), .i_tick(tick_msec), .mode(mode),
        .run_stop(runstop), .clear(clear), .load(load),
        .value(saved_msec_reg), .time_cnt(m_sec), .o_tick(tick_sec)
    );

    stopwatch_time_counter #(.COUNT_NUM(60)) U_SEC (
        .clk(clk), .reset(reset), .i_tick(tick_sec), .mode(mode),
        .run_stop(runstop), .clear(clear), .load(load),
        .value(saved_sec_reg), .time_cnt(sec), .o_tick(tick_min)
    );

    stopwatch_time_counter #(.COUNT_NUM(60)) U_MIN (
        .clk(clk), .reset(reset), .i_tick(tick_min), .mode(mode),
        .run_stop(runstop), .clear(clear), .load(load),
        .value(saved_min_reg), .time_cnt(min), .o_tick(tick_hour)
    );

    stopwatch_time_counter #(.COUNT_NUM(24)) U_HOUR (
        .clk(clk), .reset(reset), .i_tick(tick_hour), .mode(mode),
        .run_stop(runstop), .clear(clear), .load(load),
        .value(saved_hour_reg), .time_cnt(hour), .o_tick()
    );
endmodule

module stopwatch_time_counter #(
    parameter integer COUNT_NUM = 100,
    parameter integer COUNT_WIDTH = (COUNT_NUM <= 1) ? 1 : $clog2(COUNT_NUM)
) (
    input                    clk,
    input                    reset,
    input                    i_tick,
    input                    mode,
    input                    run_stop,
    input                    clear,
    input                    load,
    input  [COUNT_WIDTH-1:0] value,
    output reg [COUNT_WIDTH-1:0] time_cnt,
    output reg               o_tick
);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            time_cnt <= 0;
            o_tick   <= 1'b0;
        end else begin
            o_tick <= 1'b0;
            if (clear) begin
                time_cnt <= 0;
            end else if (load) begin
                time_cnt <= value;
            end else if (i_tick && run_stop) begin
                if (!mode) begin
                    if (time_cnt == COUNT_NUM - 1) begin
                        time_cnt <= 0;
                        o_tick   <= 1'b1;
                    end else begin
                        time_cnt <= time_cnt + 1'b1;
                    end
                end else begin
                    if (time_cnt == 0) begin
                        time_cnt <= COUNT_NUM - 1;
                        o_tick   <= 1'b1;
                    end else begin
                        time_cnt <= time_cnt - 1'b1;
                    end
                end
            end
        end
    end
endmodule

module stopwatch_tick_gen #(
    parameter integer F_COUNT = 1_000_000,
    parameter integer COUNT_WIDTH = (F_COUNT <= 1) ? 1 : $clog2(F_COUNT)
) (
    input  clk,
    input  reset,
    output reg o_tick
);
    reg [COUNT_WIDTH-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
        end else if (F_COUNT <= 1 || counter_reg == F_COUNT - 1) begin
            counter_reg <= 0;
            o_tick      <= 1'b1;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            o_tick      <= 1'b0;
        end
    end
endmodule
