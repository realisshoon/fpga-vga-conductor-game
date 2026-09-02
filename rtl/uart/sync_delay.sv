`timescale 1ns / 1ps

module sync_delay (
    input  logic clk,
    input  logic rst,
    input  logic pixel_dec_sync,
    output logic tx_sync
);
    typedef enum logic {
        IDLE  = 1'b0,
        COUNT
    } state_e;
    state_e c_state, n_state;
    logic n_enable, enable;

    // sync counter
    logic [3:0] cnt;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 0;
            tx_sync <= 1'b0;
        end else begin
            if (enable) begin
                if (cnt == 16 - 1) begin
                    cnt <= 0;
                    tx_sync <= 1'b1;
                end else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            enable  <= 0;
        end else begin
            c_state <= n_state;
            enable  <= n_enable;
        end
    end

    always_comb begin
        n_state  = c_state;
        n_enable = enable;
        case (c_state)
            IDLE: begin
                n_enable =1'b0;
                if (pixel_dec_sync) begin
                    n_state  = COUNT;
                    n_enable = 1'b1;
                end
            end
            COUNT: begin
                if (cnt == 15) begin
                    n_state  = IDLE;
                    n_enable = 1'b0;
                end
            end
        endcase
    end

endmodule
