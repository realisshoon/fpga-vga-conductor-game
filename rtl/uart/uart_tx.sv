`timescale 1ns / 1ps

module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       baud_tick,
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic       busy,
    output logic       tx
);
    // state enum
    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START,
        DATA,
        STOP
    } state_e;

    state_e c_state, n_state;
    // shift register
    logic [2:0] bit_cnt, n_bit_cnt;
    logic [7:0] tx_shift_reg, n_tx_shift_reg;
    logic n_tx, n_busy;

    // current state register
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt      <= 0;
            tx_shift_reg <= 0;
            tx           <= 1'b1;
            busy         <= 1'b0;
        end else begin
            c_state      <= n_state;
            bit_cnt      <= n_bit_cnt;
            tx_shift_reg <= n_tx_shift_reg;
            tx           <= n_tx;
            busy         <= n_busy;
        end
    end

    // next state CL
    always_comb begin
        n_state = c_state;
        case (c_state)
            IDLE: if (start) n_state = START;
            START: if (baud_tick) n_state = DATA;
            DATA: if (baud_tick == 1 && bit_cnt == 7) n_state = STOP;
            STOP: if (baud_tick) n_state = IDLE;
            default: n_state = c_state;
        endcase
    end

    // output CL
    always_comb begin
        n_busy = busy;
        n_tx = tx;
        n_bit_cnt = bit_cnt;
        n_tx_shift_reg = tx_shift_reg;
        case (c_state)
            IDLE: begin
                if (start) begin
                    n_busy = 1'b1;
                    n_tx = 1'b0;
                    n_tx_shift_reg = tx_data;
                end
            end
            START: begin
                if (baud_tick) n_tx = tx_shift_reg[0];
            end
            DATA: begin
                if (baud_tick) begin
                    if (bit_cnt == 7) begin
                        n_bit_cnt = 0;
                        n_tx_shift_reg = 0;
                        n_tx = 1'b1;
                    end else begin
                        n_bit_cnt = bit_cnt + 1;
                        n_tx_shift_reg = {1'b0, tx_shift_reg[7:1]};
                        n_tx = n_tx_shift_reg[0];
                    end
                end
            end
            STOP: begin
                if (baud_tick) begin
                    n_tx   = 1'b1;
                    n_busy = 1'b0;
                end
            end
            default: begin
                n_busy = busy;
                n_tx = tx;
                n_bit_cnt = bit_cnt;
                n_tx_shift_reg = tx_shift_reg;
            end
        endcase
    end


endmodule
