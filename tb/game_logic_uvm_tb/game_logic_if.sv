`timescale 1ns / 1ps

interface game_logic_if (
    input logic clk
);
    // DUT의 입력과 출력을 UVM component들이 함께 접근하는 신호 묶음이다.
    logic rst;
    logic [9:0] i_stick_x_pixel, i_stick_y_pixel, i_hand_y_pixel;
    logic i_vsync;
    logic [2:0] i_pc_state, i_pc_song;
    logic pattern_control_ready, stick_control_ready, volume_control_ready;
    logic game_control_ready, score_control_ready;

    logic pattern_control_valid, o_pattern_tick, score_pattern_tick;
    logic state_change_enable, stick_control_valid;
    logic [2:0] o_pattern_state;
    logic [7:0] o_speed;
    logic volume_control_valid;
    logic [6:0] o_volume_level;
    logic game_control_valid;
    logic [1:0] o_game_state;
    logic o_game_start, o_game_done, o_score_en;
    logic score_control_valid;
    logic [3:0] o_score;
    logic [2:0] o_song_num;
    logic [7:0] o_song_bpm;
    logic [9:0] speed_ram [0:3];
    logic [2:0] score_state;
    logic [1:0] score_tick_cnt;

    // 이번 검증에서는 후단이 데이터를 항상 받을 수 있도록 모든 ready를 1로 고정한다.
    assign pattern_control_ready = 1'b1;
    assign stick_control_ready   = 1'b1;
    assign volume_control_ready  = 1'b1;
    assign game_control_ready    = 1'b1;
    assign score_control_ready   = 1'b1;
endinterface
