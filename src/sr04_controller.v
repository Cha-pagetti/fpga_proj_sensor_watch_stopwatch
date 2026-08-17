`timescale 1ns / 1ps

// HC-SR04 ultrasonic sensor controller.
// - Synchronizes the asynchronous echo input.
// - Generates a 10 us trigger pulse.
// - Measures echo high time without a divider in the distance datapath.
// - Rejects missing/overlong echo pulses and enforces a re-arm interval.
module sr04_controller #(
    parameter integer CLK_FREQ_HZ           = 100_000_000,
    parameter integer TRIGGER_US            = 10,
    parameter integer ECHO_START_TIMEOUT_US = 36_000,
    parameter integer ECHO_MAX_US           = 23_200,
    parameter integer REARM_US              = 60_000
) (
    input        clk,
    input        reset,
    input        i_start,
    input        echo,
    output reg   trigger,
    output reg   o_done,
    output reg   o_ready,
    output reg   o_error,
    output [8:0] distance
);

    localparam integer US_DIV = CLK_FREQ_HZ / 1_000_000;
    localparam integer US_DIV_WIDTH = (US_DIV <= 1) ? 1 : $clog2(US_DIV);
    localparam integer TRIGGER_WIDTH = (TRIGGER_US <= 1) ? 1 : $clog2(TRIGGER_US + 1);
    localparam integer WAIT_WIDTH = (ECHO_START_TIMEOUT_US <= 1) ? 1 : $clog2(ECHO_START_TIMEOUT_US + 1);
    localparam integer ECHO_WIDTH = (ECHO_MAX_US <= 1) ? 1 : $clog2(ECHO_MAX_US + 2);
    localparam integer REARM_WIDTH = (REARM_US <= 1) ? 1 : $clog2(REARM_US + 1);

    localparam [2:0] IDLE      = 3'd0;
    localparam [2:0] TRIGGER   = 3'd1;
    localparam [2:0] WAIT_ECHO = 3'd2;
    localparam [2:0] MEASURE   = 3'd3;
    localparam [2:0] REARM     = 3'd4;

    reg [2:0] state_reg;

    reg [US_DIV_WIDTH-1:0] us_div_reg;
    wire tick_us;
    wire restart_us_tick;

    reg echo_meta_reg;
    reg echo_sync_reg;

    reg [TRIGGER_WIDTH-1:0] trigger_count_reg;
    reg [WAIT_WIDTH-1:0] wait_count_reg;
    reg [ECHO_WIDTH-1:0] echo_count_reg;
    reg [REARM_WIDTH-1:0] rearm_count_reg;
    reg [5:0] cm_count_reg;
    reg [8:0] distance_reg;

    assign distance = distance_reg;
    assign restart_us_tick = (state_reg == IDLE) && i_start;
    assign tick_us = (US_DIV <= 1) ? 1'b1 : (us_div_reg == US_DIV - 1);

    // Echo is asynchronous to the FPGA clock, so two flip-flops are required.
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            echo_meta_reg <= 1'b0;
            echo_sync_reg <= 1'b0;
        end else begin
            echo_meta_reg <= echo;
            echo_sync_reg <= echo_meta_reg;
        end
    end

    // Free-running 1 us clock-enable. It is re-aligned for every measurement.
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            us_div_reg <= 0;
        end else if (restart_us_tick) begin
            us_div_reg <= 0;
        end else if (US_DIV <= 1) begin
            us_div_reg <= 0;
        end else if (tick_us) begin
            us_div_reg <= 0;
        end else begin
            us_div_reg <= us_div_reg + 1'b1;
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg         <= IDLE;
            trigger           <= 1'b0;
            o_done            <= 1'b0;
            o_ready           <= 1'b1;
            o_error           <= 1'b0;
            trigger_count_reg <= 0;
            wait_count_reg    <= 0;
            echo_count_reg    <= 0;
            rearm_count_reg   <= 0;
            cm_count_reg      <= 0;
            distance_reg      <= 0;
        end else begin
            // Completion and error are one-clock pulses.
            o_done  <= 1'b0;
            o_error <= 1'b0;

            case (state_reg)
                IDLE: begin
                    trigger <= 1'b0;
                    o_ready <= 1'b1;
                    if (i_start) begin
                        state_reg         <= TRIGGER;
                        trigger           <= 1'b1;
                        o_ready           <= 1'b0;
                        trigger_count_reg <= 0;
                        wait_count_reg    <= 0;
                        echo_count_reg    <= 0;
                        cm_count_reg      <= 0;
                        distance_reg      <= 0;
                    end
                end

                TRIGGER: begin
                    trigger <= 1'b1;
                    if (tick_us) begin
                        if (trigger_count_reg == TRIGGER_US - 1) begin
                            state_reg         <= WAIT_ECHO;
                            trigger           <= 1'b0;
                            trigger_count_reg <= 0;
                            wait_count_reg    <= 0;
                        end else begin
                            trigger_count_reg <= trigger_count_reg + 1'b1;
                        end
                    end
                end

                WAIT_ECHO: begin
                    trigger <= 1'b0;
                    if (echo_sync_reg) begin
                        state_reg      <= MEASURE;
                        echo_count_reg <= 0;
                        cm_count_reg   <= 0;
                    end else if (tick_us) begin
                        if (wait_count_reg >= ECHO_START_TIMEOUT_US - 1) begin
                            state_reg       <= REARM;
                            rearm_count_reg <= 0;
                            distance_reg    <= 0;
                            o_error         <= 1'b1;
                        end else begin
                            wait_count_reg <= wait_count_reg + 1'b1;
                        end
                    end
                end

                MEASURE: begin
                    if (!echo_sync_reg) begin
                        state_reg       <= REARM;
                        rearm_count_reg <= 0;
                        o_done          <= 1'b1;
                    end else if (tick_us) begin
                        if (echo_count_reg >= ECHO_MAX_US) begin
                            state_reg       <= REARM;
                            rearm_count_reg <= 0;
                            distance_reg    <= 0;
                            o_error         <= 1'b1;
                        end else begin
                            echo_count_reg <= echo_count_reg + 1'b1;
                            if (cm_count_reg == 6'd57) begin
                                cm_count_reg <= 0;
                                if (distance_reg < 9'd400)
                                    distance_reg <= distance_reg + 1'b1;
                            end else begin
                                cm_count_reg <= cm_count_reg + 1'b1;
                            end
                        end
                    end
                end

                REARM: begin
                    trigger <= 1'b0;
                    if (tick_us) begin
                        if (rearm_count_reg >= REARM_US - 1) begin
                            state_reg       <= IDLE;
                            rearm_count_reg <= 0;
                            o_ready         <= 1'b1;
                        end else begin
                            rearm_count_reg <= rearm_count_reg + 1'b1;
                        end
                    end
                end

                default: begin
                    state_reg <= IDLE;
                    trigger   <= 1'b0;
                    o_ready   <= 1'b1;
                end
            endcase
        end
    end
endmodule

// Backward-compatible wrapper used by the earlier project files.
module sr04_ctrl #(
    parameter integer CLK_FREQ_HZ = 100_000_000
) (
    input        clk,
    input        reset,
    input        start,
    input        echo,
    output       trigger,
    output       done,
    output [8:0] distance
);
    sr04_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) U_SR04_CONTROLLER (
        .clk(clk),
        .reset(reset),
        .i_start(start),
        .echo(echo),
        .trigger(trigger),
        .o_done(done),
        .o_ready(),
        .o_error(),
        .distance(distance)
    );
endmodule
