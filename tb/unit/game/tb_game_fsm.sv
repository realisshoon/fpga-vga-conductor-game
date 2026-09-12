`timescale 1ns / 1ps
module tb_game_fsm ();

    logic       clk;
    logic       rst;
    logic [2:0] i_pc_state;
    logic [2:0] i_pattern_state;
    logic       game_control_ready;
    logic       game_control_valid;
    logic [1:0] o_game_state;
    logic       o_game_start;
    logic       o_game_done;
    logic       o_score_en;


    typedef enum logic [1:0] {

        IDLE = 2'b00,
        READY,
        GAME_ING
    } game_state_e;

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



    game_fsm dut (
        .clk(clk),
        .rst(rst),
        .i_pc_state(i_pc_state),
        .i_pattern_state(i_pattern_state),
        .game_control_ready(game_control_ready),
        .game_control_valid(game_control_valid),
        .o_game_state(o_game_state),
        .o_game_start(o_game_start),
        .o_game_done(o_game_done),
        .o_score_en(o_score_en)
    );



    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        i_pc_state = 0;
        i_pattern_state = 0;
        game_control_ready = 0;

        repeat (3) @(posedge clk);
        rst = 0;
        game_control_ready = 1;

        repeat (5) @(posedge clk);

        i_pc_state = PC_READY;
        repeat (5) @(posedge clk);

        i_pattern_state = SK_READY;
        repeat (2) @(posedge clk);
        i_pc_state = PC_GAME_ING;


        repeat (5) @(posedge clk);
        i_pattern_state = SK_PATTERN_1;
        repeat (5) @(posedge clk);
        i_pc_state = PC_STOP;
        repeat (5) @(posedge clk);


        $stop;

    end

endmodule
