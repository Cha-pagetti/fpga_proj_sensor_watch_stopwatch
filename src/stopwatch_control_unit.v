`timescale 1ns / 1ps

// Standalone stopwatch controller retained for block-level use.
module stopwatch_control_unit (
    input  clk,
    input  reset,
    input  i_runstop,
    input  i_ascii_run,
    input  i_ascii_stop,
    input  i_clear,
    input  i_mode,
    input  i_save_load,
    input  i_is_data_saved,
    input  i_ascii_save,
    input  i_ascii_load,
    output reg o_runstop,
    output reg o_clear,
    output reg o_mode,
    output reg o_save,
    output reg o_load
);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_runstop <= 1'b0;
            o_clear   <= 1'b0;
            o_mode    <= 1'b0;
            o_save    <= 1'b0;
            o_load    <= 1'b0;
        end else begin
            o_clear <= 1'b0;
            o_save  <= 1'b0;
            o_load  <= 1'b0;

            if (i_ascii_run)
                o_runstop <= 1'b1;
            else if (i_ascii_stop)
                o_runstop <= 1'b0;
            else if (i_runstop)
                o_runstop <= ~o_runstop;

            if (i_clear)
                o_clear <= 1'b1;
            if (i_mode)
                o_mode <= ~o_mode;

            if ((i_save_load || i_ascii_save) && !i_is_data_saved)
                o_save <= 1'b1;
            else if ((i_save_load || i_ascii_load) && i_is_data_saved)
                o_load <= 1'b1;
        end
    end
endmodule
