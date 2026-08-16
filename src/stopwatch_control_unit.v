`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,
    input i_runstop,
    input i_ascii_run,
    input i_ascii_stop,
    input i_clear,
    input i_mode,
    input i_save_load,  // btn down
    input i_is_data_saved, // datapath에 데이터 저장되어 있는지 t/f 
    input i_ascii_save,
    input i_ascii_load,
    output o_runstop,
    output o_clear,
    output o_mode,
    output o_save,  // data save trigger signal
    output o_load  // data load trigger signal

);
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, MODE = 3'b011, SAVE = 3'b100, LOAD = 3'b101;

    reg [2:0] c_state, n_state;
    //reg는 current, next는 next, 출력도 피드백구조로 만들기
    reg run_stop_reg, clear_reg, mode_reg, save_reg, load_reg;
    reg run_stop_next, clear_next, mode_next, save_next, load_next;

    //output
    //assign {o_clear, o_runstop, o_mode} = (c_state == STOP) ? 3'b000:
    //                                        (c_state === RUN) ? 3'b010:
    //                                        (c_state == CLEAR) ? 3'b100:
    //                                        (c_state == MODE) ? 3'b000: 3'b000;
    // assign문을 always로 바꾸기

    assign o_runstop = run_stop_reg;
    assign o_clear = clear_reg;
    assign o_mode = mode_reg;
    assign o_save = save_reg;
    assign o_load = load_reg;

    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= STOP;
            run_stop_reg <= 1'b0;
            clear_reg <= 1'b0;
            mode_reg <= 1'b0;
            save_reg <= 1'b0;
            load_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            run_stop_reg <= run_stop_next;
            clear_reg <= clear_next;
            mode_reg <= mode_next;
            save_reg <= save_next;
            load_reg <= load_next;
        end
    end

    //next CL 
    always @(*) begin
        n_state = c_state;
        run_stop_next = run_stop_reg;
        clear_next = clear_reg;
        mode_next = mode_reg;
        save_next = save_reg;
        load_next = load_reg;
        case (c_state)
            STOP: begin
                //moore output
                run_stop_next = 1'b0;
                clear_next = 1'b0;
                load_next = 1'b0;
                save_next = 1'b0;
                if (i_runstop | i_ascii_run) n_state = RUN;
                else if (i_clear) n_state = CLEAR;
                else if (i_mode) n_state = MODE;
                else if ((i_save_load | i_ascii_save) & !i_is_data_saved) n_state = SAVE;
                else if ((i_save_load | i_ascii_load) & i_is_data_saved) n_state = LOAD;
                else n_state = c_state;
            end
            RUN: begin
                run_stop_next = 1'b1;
                if (i_runstop | i_ascii_stop) begin
                    n_state = STOP;
                end
            end
            CLEAR: begin
                clear_next = 1'b1;
                n_state = STOP;
            end
            MODE: begin
                mode_next = ~mode_reg;
                n_state   = STOP;
            end
            SAVE: begin
                save_next = 1'b1;
                n_state   = STOP;
            end
            LOAD: begin
                load_next = 1'b1;
                n_state   = STOP;
            end
        endcase
    end

endmodule
