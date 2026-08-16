`timescale 1ns / 1ps

// Small synchronous FIFO with a combinational front-data output.
// WIDTH is the address width, so the FIFO depth is 2**WIDTH.
module fifo #(
    parameter integer WIDTH = 2
) (
    input        clk,
    input        reset,
    input  [7:0] wData,
    input        push,
    input        pop,
    output [7:0] rData,
    output       full,
    output       empty
);
    localparam integer DEPTH = 1 << WIDTH;

    reg [7:0] mem [0:DEPTH-1];
    reg [WIDTH-1:0] write_ptr_reg;
    reg [WIDTH-1:0] read_ptr_reg;
    reg [WIDTH:0] count_reg;

    wire do_pop;
    wire do_push;

    assign empty = (count_reg == 0);
    assign full  = (count_reg == DEPTH);
    assign rData = mem[read_ptr_reg];

    assign do_pop  = pop && !empty;
    // A pop frees one slot on the same edge, so full FIFOs may push and pop together.
    assign do_push = push && (!full || do_pop);

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            write_ptr_reg <= 0;
            read_ptr_reg  <= 0;
            count_reg     <= 0;
        end else begin
            if (do_push) begin
                mem[write_ptr_reg] <= wData;
                write_ptr_reg      <= write_ptr_reg + 1'b1;
            end

            if (do_pop)
                read_ptr_reg <= read_ptr_reg + 1'b1;

            case ({do_push, do_pop})
                2'b10: count_reg <= count_reg + 1'b1;
                2'b01: count_reg <= count_reg - 1'b1;
                default: count_reg <= count_reg;
            endcase
        end
    end
endmodule
