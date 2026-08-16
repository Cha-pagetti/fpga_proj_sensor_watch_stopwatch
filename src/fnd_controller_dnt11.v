`timescale 1ns / 1ps

module fnd_controller_dht11 (
    input         clk,
    input         reset,
    input  [15:0] fnd_in,   // 14bit 10000진 카운트 변수 받을 준비
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data
);
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire [3:0] bcd;
    wire [1:0] w_digit_sel;
    wire clk_reg;

    clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .o_1khz(clk_reg)
    );

    counter_4 U_COUNTER_4 (
        .clk(clk_reg),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DC (
        .sel(w_digit_sel),
        .an_com(fnd_com)
    );

    digit_splitter U_DS (
        .seg_data(fnd_in),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4x1 U_MUX (
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .sel(w_digit_sel),
        .mux_out(bcd)
    );

    bcd U_BCD (
        .bcd_in (bcd),
        .bcd_out(fnd_data)
    );

endmodule

module clk_div (
    input  clk,
    input  reset,
    output o_1khz
);

    reg [15:0] counter_reg;
    reg clk_reg;

    assign o_1khz = clk_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_reg <= 1'b0;
        end else begin
            // <= non blocking은 일단 예약 걸고 always 끝난 다음 한번에 반영
            counter_reg <= counter_reg + 1;
            // if문에서 읽어오는 건 예약 반영되기 전의 값.
            if (counter_reg == (50000 - 1)) begin
                counter_reg <= 0;
                clk_reg <= ~clk_reg;
            end
        end
    end

endmodule

module counter_4 (
    input clk,
    input reset,
    output [1:0] digit_sel
);

    reg [1:0] counter_reg;
    // output과 counter_reg 연결
    // output을 reg로 바꾸는 거랑 차이 없음
    assign digit_sel = counter_reg;

    // sequential logic (SL)
    // reset: clock 비동기 reset
    // reset을 넣어야 하는 이유: counter_reg의 초기화를 위함. 초기화하지 않으면 x라 동작이 이상함
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end else begin
            // operation
            // reset은 0이고 clk 상승엣지가 온 것 -> 바로 +1
            // 자동으로 0~3 까지만 카운트: 11 + 1 = 00 (c는 날아감)
            counter_reg <= counter_reg + 1;
        end
    end

endmodule

module digit_splitter (
    input  [15:0] seg_data,   // 13bit로 변경
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);

    assign digit_100 = seg_data[15:8] % 10;
    assign digit_1000 = (seg_data[15:8] / 10) % 10;
    assign digit_1 = seg_data[8:0] % 10;
    assign digit_10 = (seg_data[8:0] / 10) % 10;

endmodule

module mux_4x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [1:0] sel,
    output [3:0] mux_out
);

    // always @(sel) begin
    //     case (sel)
    //         2'b00:   mux_out = digit_1;
    //         2'b01:   mux_out = digit_10;
    //         2'b10:   mux_out = digit_100;
    //         2'b11:   mux_out = digit_1000;
    //         default: mux_out = 4'b0000;
    //     endcase
    // end

    assign mux_out = (sel == 2'b00) ? digit_1 : 
                     (sel == 2'b01) ? digit_10 : 
                     (sel == 2'b10) ? digit_100 : 
                     (sel == 2'b11) ? digit_1000 :
                     4'b1111;

endmodule

module decoder_2x4 (
    input [1:0] sel,
    output reg [3:0] an_com
);

    always @(sel) begin
        case (sel)
            2'b00:   an_com = 4'b1110;
            2'b01:   an_com = 4'b1101;
            2'b10:   an_com = 4'b1011;
            2'b11:   an_com = 4'b0111;
            default: an_com = 4'b1111;
        endcase
    end

endmodule


module bcd (
    input [3:0] bcd_in,
    output reg [7:0] bcd_out
);

    // bcd_in 값이 바뀔때마다 (이벤트 발생) begin
    // 내부에 assign 문 사용 불가
    // always 구문의 출력은 항상 reg 타입이어야 함
    always @(bcd_in) begin
        case (bcd_in)
            4'b0000: bcd_out = 8'hC0;  // 0
            4'b0001: bcd_out = 8'hF9;  // 1
            4'b0010: bcd_out = 8'hA4;  // 2
            4'b0011: bcd_out = 8'hB0;  // 3
            4'b0100: bcd_out = 8'h99;  // 4
            4'b0101: bcd_out = 8'h92;  // 5
            4'b0110: bcd_out = 8'h82;  // 6
            4'b0111: bcd_out = 8'hF8;  // 7
            4'b1000: bcd_out = 8'h80;  // 8
            4'b1001: bcd_out = 8'h90;  // 9
            4'b1010: bcd_out = 8'h88;  // a
            4'b1011: bcd_out = 8'h83;  // b
            4'b1100: bcd_out = 8'hC6;  // c
            4'b1101: bcd_out = 8'hA1;  // d
            4'b1110: bcd_out = 8'h86;  // e
            4'b1111: bcd_out = 8'h8e;  // f
        endcase
    end

endmodule
