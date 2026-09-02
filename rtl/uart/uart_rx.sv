`timescale 1ns / 1ps

module uart_rx #(
    parameter BW = 8
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          sampling_tick,
    input  logic          rx,
    output logic          done,
    output logic [BW-1:0] o_rx_data
);

    //
    logic [3:0] samp_tick_cnt, n_samp_tick_cnt;
    logic [2:0] bit_cnt, n_bit_cnt;
    logic n_done;
    logic [BW-1:0] rx_data, n_rx_data;

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } state_e;

    state_e c_state, n_state;

    // 2 stage FF sync, edge detecting
    logic rx_1;
    logic rx_2;
    logic start;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            rx_1  <= 1'b0;
            rx_2  <= 1'b0;
            start <= 1'b0;
        end else begin
            rx_1 <= rx;
            rx_2 <= rx_1;
            if (~rx_1 & rx_2) start <= 1'b1;
            else start <= 1'b0;
        end
    end

    // current state register
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
        end else begin
            c_state <= n_state;
        end
    end
    // next_state CL
    always_comb begin
        n_state = c_state;
        case (c_state)
            IDLE: if (start) n_state = START;
            START: begin
                if (sampling_tick && samp_tick_cnt == 7) begin
                    if (rx_2 == 1'b0) n_state = DATA;
                    else n_state = IDLE;
                end
            end
            DATA:
            if (sampling_tick && bit_cnt == 7 && samp_tick_cnt == 15)
                n_state = STOP;
            STOP: if (sampling_tick && samp_tick_cnt == 15) n_state = IDLE;

        endcase
    end

    // current output register
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            o_rx_data <= 0;
            rx_data       <= 0;
            samp_tick_cnt <= 0;
            bit_cnt       <= 0;
            done          <= 1'b0;
        end else begin
            if(done) begin
                o_rx_data <= rx_data;
            end
            rx_data       <= n_rx_data;
            samp_tick_cnt <= n_samp_tick_cnt;
            bit_cnt       <= n_bit_cnt;
            done          <= n_done;
        end
    end

    // output CL
    always_comb begin
        n_rx_data = rx_data;
        n_samp_tick_cnt = samp_tick_cnt;
        n_bit_cnt = bit_cnt;
        n_done = done;
        case (c_state)
            IDLE: begin
                n_done = 1'b0;
            end
            START: begin
                if (sampling_tick) begin
                    if (samp_tick_cnt == 7) begin
                        n_samp_tick_cnt = 0;
                    end else begin
                        n_samp_tick_cnt = samp_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (sampling_tick) begin
                    if (samp_tick_cnt == 15) begin
                        n_rx_data = {rx_2, rx_data[7:1]};
                        n_samp_tick_cnt = 0;
                        if (bit_cnt == 7) begin
                            n_bit_cnt = 0;
                        end else begin
                            n_bit_cnt = bit_cnt + 1;
                        end
                    end else begin
                        n_samp_tick_cnt = samp_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (sampling_tick) begin
                    if (samp_tick_cnt == 15) begin
                        n_samp_tick_cnt = 0;
                        if (rx_2 == 1'b1) begin
                            n_done = 1'b1;
                        end else n_done = 1'b0;
                    end
                end
            end
            default: begin
            end
        endcase
    end

endmodule
