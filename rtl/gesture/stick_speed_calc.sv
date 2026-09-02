`timescale 1ns / 1ps

module stick_speed_calc #(
    parameter CLK_FREQ = 100_000_000
) (

    input  logic       clk,
    input  logic       rst,
    input  logic       i_vsync,
    input  logic       i_pattern_tick,
    input  logic [2:0] pattern_state,
    input  logic       stick_control_ready,
    output logic       stick_control_valid,
    output logic       o_pattern_tick,
    output logic [7:0] o_speed

);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        READY,
        PATTERN_1,
        PATTERN_2,
        PATTERN_3,
        PATTERN_4,
        STOP
    } pattern_state_e;

    //    localparam IDLE = 3'd0, START = 3'd1, STOP = 3'd6;

    logic [27:0] count_reg;

    logic counting; // 첫 번째 pattern_tick이 들어와서 현재 시간 측정 중인지 표시

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count_reg           <= 28'd0;
            counting            <= 0;
            o_speed             <= 8'd0;
            stick_control_valid <= 0;
            o_pattern_tick      <= 0;
        end else begin
            if (stick_control_valid && stick_control_ready) begin
                stick_control_valid <= 0;
            end
            if (!(pattern_state == IDLE) && !(pattern_state == READY) && !(pattern_state == START) && !(pattern_state == STOP)) begin
                o_pattern_tick <= 0;
                if (i_pattern_tick) begin
                    if (!counting) begin
                        count_reg <= 0;
                        counting  <= 1;
                    end else begin
                        o_speed <= (64'd60 * CLK_FREQ) / (count_reg + 1);
                        o_pattern_tick <= 1;
                        count_reg <= 28'd0;
                        stick_control_valid <= 1;
                    end
                end else if (counting) begin
                    count_reg <= count_reg + 28'd1;
                end
            end else begin
                count_reg <= 28'd0;
                o_speed   <= 0;
                counting  <= 0;
            end
            if (i_vsync) begin
                stick_control_valid <= 0;
            end
        end
    end

endmodule
