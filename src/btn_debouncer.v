`timescale 1ns / 1ps

module btn_debouncer (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    // 100khz는 6개 이상 쓰면 오동작이 없음
    // bit 너무 적게써도 오동작 발생
    reg [7:0] q_reg;  // SIPO 8tab shift reg
    reg w_1mhz;
    reg [$clog2(50):0] counter_reg;
    wire debounce;
    reg edge_reg;

    // clk divier - 100분주
    // 100mhz clk -> 1mhz w_clk 
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            w_1mhz <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == 50 - 1) begin
                counter_reg <= 0;
                w_1mhz <= ~w_1mhz;
            end
        end
    end

    // 8bit shift register, SIPO
    always @(posedge w_1mhz, posedge reset) begin
        if (reset) begin
            q_reg[7:0] <= 8'h00;
        end else begin
            q_reg <= {i_btn, q_reg[7:1]};  // 우측 shift
            // q_reg <= {q_reg[6:0], i_btn}; // 좌측 shift
        end
    end

    // 디바운스된 신호
    assign debounce = &q_reg;

    // f/f - 1 clk delay
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    // btn 입력의 posedge tick만 추출
    assign o_btn = debounce & ~edge_reg;

endmodule
