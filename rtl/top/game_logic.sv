`timescale 1ns / 1ps
module game_logic (
    input logic clk,
    input logic rst,

    // from rg_detect
    input  logic [9:0] i_stick_x_pixel,
    input  logic [9:0] i_stick_y_pixel,
    // input  logic [ 9:0] i_hand_x_pixel,
    input  logic [9:0] i_hand_y_pixel,
    input  logic       i_vsync,
    // for uart_wrapper signal
    // volume value data
    input  logic       volume_uart_ready,
    output logic       volume_uart_valid,
    output logic [6:0] o_volume_level,
    // speed bpm data
    input  logic       stick_control_ready,
    output logic       stick_control_valid,
    output logic [7:0] o_speed,
    // game score data
    input  logic       score_control_ready,
    output logic       score_control_valid,
    output logic [3:0] o_score,
    // game state data
    input  logic       game_control_ready,
    output logic       game_control_valid,
    output logic [1:0] o_game_state,
    // gatten state data
    input  logic       pattern_control_ready,
    output logic       pattern_control_valid,
    output logic [2:0] o_pattern_state,
    // from pc to uart rx data
    input  logic [2:0] i_pc_state,
    input  logic [2:0] i_pc_song
);
    logic       w_score_en;
    logic [2:0] w_pattern_state;
    logic       w_pattern_tick;
    logic       w_score_pattern_tick;
    logic [7:0] w_speed;
    logic [7:0] w_song_bpm;
    // logic [2:0] w_song_num;
    logic       w_game_start;
    logic       w_game_done;
    logic       w_state_change_enable;

    assign o_speed = w_speed;
    assign o_pattern_state = w_pattern_state;

    game_fsm u_game_fsm (
        .clk(clk),
        .rst(rst),
        .i_pc_state(i_pc_state),
        .i_pattern_state(w_pattern_state),
        .game_control_ready(game_control_ready),
        .game_control_valid(game_control_valid),
        .o_game_state(o_game_state),
        .o_game_start(w_game_start),
        .o_game_done(w_game_done),
        .o_score_en(w_score_en)
    );


    game_score u_game_score (
        .clk(clk),
        .rst(rst),
        .i_score_en(w_score_en),
        .i_pattern_tick(w_score_pattern_tick),
        .i_speed(w_speed),
        // input logic [2:0] i_song_num,
        .i_song_speed(w_song_bpm),
        .score_control_ready(score_control_ready),
        .score_control_valid(score_control_valid),
        .o_score(o_score)
    );

    pattern_stick u_pattern_stick (
        .clk(clk),
        .rst(rst),
        .game_start(w_game_start),
        .game_stop(w_game_done),
        .i_stick_x_pixel(i_stick_x_pixel),
        .i_stick_y_pixel(i_stick_y_pixel),
        .i_vsync(i_vsync),
        .pattern_control_ready(pattern_control_ready),
        .pattern_control_valid(pattern_control_valid),
        .pattern_state(w_pattern_state),
        .pattern_tick(w_pattern_tick),
        .i_state_change_enable(w_state_change_enable)  // speed 계산 모듈과 연결 되어야함
    );

    volume_ctrl u_vol_control (
        .clk(clk),
        .rst(rst),
        // xy_detection
        .i_vsync(i_vsync),  // 새로운 프레임 좌표가 갱신됨.
        .i_hand_y_pixel(i_hand_y_pixel),  // 현재 손의 y 좌표
        // tx_data control interface                    
        .volume_control_ready(volume_uart_ready),  // tx_data 제어 모듈이 볼륨 데이터를 받을 수 있음.
        .volume_control_valid(volume_uart_valid),  // 새로운 볼륨 데이터가 준비됨.
        .o_volume_level(o_volume_level)  // 계산된 볼륨 0 ~ 100
    );

    stick_speed_calc u_speed_calc (
        .clk(clk),
        .rst(rst),
        .i_vsync(i_vsync),
        .pattern_state(w_pattern_state),
        .i_pattern_tick(w_pattern_tick),
        .i_pc_song_bpm(w_song_bpm),
        .stick_control_ready(stick_control_ready),
        .stick_control_valid(stick_control_valid),
        .o_pattern_tick(w_score_pattern_tick),
        .o_speed(w_speed),
        .o_state_change_enable(w_state_change_enable)
    );


    song_decoder u_song_decoder (
        .clk(clk),
        .rst(rst),
        .i_pc_state(i_pc_state),
        .i_pc_song(i_pc_song),
        // .o_song_num(w_song_num),
        .o_song_bpm(w_song_bpm)
    );

endmodule
