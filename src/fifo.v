`timescale 1ns / 1ps

module fifo #(
    parameter WIDTH = 2
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
    wire [WIDTH-1:0] w_write_addr, w_read_addr;

    register_file #(
        .WIDTH(WIDTH)
    ) U_REG_FILE (
        .clk(clk),
        .wAddr(w_write_addr),
        .wData(wData),
        .we(push & !full),
        .rAddr(w_read_addr),
        .rData(rData)
    );

    control_unit #(
        .WIDTH(WIDTH)
    ) U_CNTL_UNIT (
        .clk  (clk),
        .reset(reset),
        .push (push),
        .pop  (pop),
        .wptr (w_write_addr),
        .rptr (w_read_addr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file #(
    parameter WIDTH = 2
) (
    input              clk,
    input  [WIDTH-1:0] wAddr,
    input  [      7:0] wData,
    input              we,
    input  [WIDTH-1:0] rAddr,
    output [      7:0] rData
);
    parameter DEPTH = 2 ** WIDTH;

    reg [7:0] register_file[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[wAddr] <= wData;
        end
        // else begin
        //     // SL output
        //     rData <= register_file[rAddr];
        // end
    end

    // CL output
    assign rData = register_file[rAddr];

endmodule


module control_unit #(
    parameter WIDTH = 2
) (
    input              clk,
    input              reset,
    input              push,
    input              pop,
    output [WIDTH-1:0] wptr,
    output [WIDTH-1:0] rptr,
    output             full,
    output             empty
);
    parameter [1:0] IDLE = 0;
    parameter [1:0] EMPTY = 1;
    parameter [1:0] FULL = 2;

    reg [1:0] c_state, n_state;

    reg [WIDTH-1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    assign wptr = wptr_reg;
    assign rptr = rptr_reg;

    reg empty_reg, empty_next, full_reg, full_next;
    assign empty = empty_reg;
    assign full  = full_reg;

    // 순차 출력 + state reg
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state   <= EMPTY;
            rptr_reg  <= 0;
            wptr_reg  <= 0;
            empty_reg <= 1;
            full_reg  <= 0;
        end else begin
            c_state   <= n_state;
            rptr_reg  <= rptr_next;
            wptr_reg  <= wptr_next;
            empty_reg <= empty_next;
            full_reg  <= full_next;
        end
    end

    // next state + output CL
    always @(*) begin
        n_state = c_state;
        rptr_next = rptr_reg;
        wptr_next = wptr_reg;
        empty_next = empty_reg;
        full_next = full_reg;

        // 상태 없이 입력으로만 조건 만들 수 있음
        case ({
            push, pop
        })
            2'b00: begin
                // init
            end
            2'b01: begin
                // pop
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) empty_next = 1'b1;
                end
            end
            2'b10: begin
                // push
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) full_next = 1'b1;
                end
            end
            2'b11: begin
                // push pop
                if (full_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase

        // case (c_state)
        //     IDLE: begin
        //         empty_next = 0;
        //         full_next  = 0;
        //         if (push & pop) begin
        //             wptr_next = wptr_reg + 1;
        //             rptr_next = rptr_reg + 1;
        //         end else if (push) begin
        //             wptr_next = wptr_reg + 1;
        //             if (wptr_next == rptr_reg) begin
        //                 n_state   = FULL;
        //                 full_next = 1;
        //             end
        //         end else if (pop) begin
        //             rptr_next = rptr_reg + 1;
        //             if (rptr_next == wptr_reg) begin
        //                 n_state = EMPTY;
        //                 empty_next = 1;
        //             end
        //         end
        //     end
        //     EMPTY: begin
        //         empty_next = 1;
        //         if (push) begin
        //             wptr_next = wptr_reg + 1;
        //             n_state = IDLE;
        //             empty_next = 0;
        //         end
        //     end
        //     FULL: begin
        //         full_next = 1;
        //         if (pop) begin
        //             rptr_next = rptr_reg + 1;
        //             n_state   = IDLE;
        //             full_next = 0;
        //         end
        //     end
        // endcase
    end

endmodule
