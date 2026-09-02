`timescale 1ns / 1ps
module game_fsm (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] i_pc_state,
    input  logic [2:0] i_pattern_state,
    input  logic       game_control_ready,
    output logic       game_control_valid,
    output logic [1:0] o_game_state,
    output logic       o_game_start,
    output logic       o_game_done,
    output logic       o_score_en
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READY,
        GAME_ING
    } game_state_e;
    game_state_e c_state;

    typedef enum logic [2:0] {
        MAIN = 3'b000,
        MENU,
        PC_READY,
        PC_GAME_ING,
        PC_STOP
    } pc_state_e;

    typedef enum logic [2:0] {
        SK_IDLE = 3'b000,
        SK_START,
        SK_READY,
        SK_PATTERN_1,
        SK_PATTERN_2,
        SK_PATTERN_3,
        SK_PATTERN_4,
        SK_STOP
    } pattern_state_e;

    logic r_game_start;
    logic r_game_done;
    logic r_score_en;

    assign o_game_start = r_game_start;
    assign o_game_done  = r_game_done;
    assign o_score_en   = r_score_en;
    assign o_game_state = c_state;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state            <= IDLE;
            game_control_valid <= 1;
            r_game_start       <= 0;
            r_game_done        <= 0;
            r_score_en         <= 0;
        end else begin
            c_state      <= c_state;
            r_game_start <= 0;
            r_game_done  <= 0;
            r_score_en   <= 0;
            if (game_control_valid && game_control_ready) begin
                game_control_valid <= 0;
            end
            case (c_state)
                IDLE: begin
                    if (i_pc_state == PC_READY) begin
                        c_state <= READY;
                        r_game_start <= 1;
                        game_control_valid <= 1;
                    end
                end
                READY: begin
                    if (i_pc_state == PC_STOP) begin
                        c_state            <= IDLE;
                        r_game_done        <= 1;
                        game_control_valid <= 1;
                    end else if (i_pattern_state == SK_PATTERN_1) begin
                        c_state <= GAME_ING;
                        game_control_valid <= 1;
                    end
                end
                GAME_ING: begin
                    r_score_en <= 1;
                    if (i_pc_state == PC_STOP) begin
                        r_score_en         <= 0;
                        c_state            <= IDLE;
                        r_game_done        <= 1;
                        game_control_valid <= 1;
                    end
                end
            endcase
        end
    end

endmodule
