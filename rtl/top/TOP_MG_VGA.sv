`timescale 1ns / 1ps

module TOP_MG_VGA #(

    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 16,
    parameter AW = $clog2(IMG_H * IMG_W),


    parameter logic [3:0] RED_MIN      = 4'd8,
    parameter logic [3:0] RED_G_MARGIN = 4'd3,
    parameter logic [3:0] RED_B_MARGIN = 4'd3,

    parameter logic [3:0] GREEN_MIN      = 4'd7,
    parameter logic [3:0] GREEN_R_MARGIN = 4'd2,
    parameter logic [3:0] GREEN_B_MARGIN = 4'd2,
    // Blue detection parameters
    parameter logic [3:0] BLUE_MIN       = 4'd9,
    parameter logic [3:0] BLUE_R_MARGIN  = 4'd4,
    parameter logic [3:0] BLUE_G_MARGIN  = 4'd4



) (
    input  logic        clk,
    input  logic        rst,

    output logic        xclk,
    input  logic        pclk,
    input  logic        cam_href,
    input  logic        cam_vsync,
    input  logic [ 7:0] cam_data,

    input  logic        sw_mode,
    input  logic        sw_invert,
    input  logic        SW_RED,
    input  logic        SW_GREEN,
    input  logic        SW_BLUE,

    output logic        scl,
    inout  logic        sda,

    output logic        H_SYNC,
    output logic        V_SYNC,
    output logic [11:0] RGB,
    
    output logic        tx,
    input  logic        rx
);

    // ---- pixel pipeline ----
    logic [ 9:0] w_x_pixel;
    logic [ 9:0] w_y_pixel;
    logic        w_de;
    logic [11:0] w_RGB;

    // ov7670_cam -> RG_detect sync passthrough
    logic        w_VGA_H_SYNC;
    logic        w_VGA_V_SYNC;

    // RG_detect outputs
    logic [39:0] w_pixel;
    logic [ 9:0] w_stick_x_pixel;
    logic [ 9:0] w_stick_y_pixel;
    // logic [ 9:0] w_hand_x_pixel;
    logic [ 9:0] w_hand_y_pixel;
    logic        w_pixel_dec_sync;

    // game_logic <-> uart_wrapper data
    logic [ 6:0] w_volume_level;
    logic [ 7:0] w_speed;
    logic [ 3:0] w_score;
    logic [ 1:0] w_game_state;
    logic [ 2:0] w_pattern_state;

    logic [ 7:0] w_rx_data;

    // ---- handshake signals (RG_detect <-> uart_wrapper) ----
    logic        w_xy_control_ready;
    logic        w_xy_control_valid;

    // ---- handshake signals (game_logic <-> uart_wrapper) ----
    logic        w_volume_uart_ready;
    logic        w_volume_uart_valid;
    logic        w_stick_control_ready;
    logic        w_stick_control_valid;
    logic        w_score_control_ready;
    logic        w_score_control_valid;
    logic        w_game_control_ready;
    logic        w_game_control_valid;
    logic        w_pattern_control_ready;
    logic        w_pattern_control_valid;

    ov7670_cam #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .DW   (DW),
        .AW   (AW)
    ) U_OV_CAM (
        // ov7670 signal
        .xclk       (xclk),
        .pclk       (pclk),
        .cam_href   (cam_href),
        .cam_vsync  (cam_vsync),
        .cam_data   (cam_data),
        // VGA controller signal
        .clk        (clk),
        .rst        (rst),
        .sw_mode    (sw_mode),
        .sw_invert  (sw_invert),
        // New VGA filter control - uppercase naming
        // output logic       v_sync,
        // output logic       h_sync,
        // output logic [3:0] port_red,
        // output logic [3:0] port_green,
        // output logic [3:0] port_blue,
        // OV7670 setup port
        .scl        (scl),
        .sda        (sda),
        .VGA_H_SYNC (w_VGA_H_SYNC),
        .VGA_V_SYNC (w_VGA_V_SYNC),
        .VGA_DE     (w_de),
        .VGA_X_PIXEL(w_x_pixel),
        .VGA_Y_PIXEL(w_y_pixel),
        .VGA_RGB    (w_RGB)
    );


    RG_detect #(
        .RED_MIN       (RED_MIN),
        .RED_G_MARGIN  (RED_G_MARGIN),
        .RED_B_MARGIN  (RED_B_MARGIN),
        .GREEN_MIN     (GREEN_MIN),
        .GREEN_R_MARGIN(GREEN_R_MARGIN),
        .GREEN_B_MARGIN(GREEN_B_MARGIN),
        .BLUE_MIN      (BLUE_MIN),
        .BLUE_R_MARGIN (BLUE_R_MARGIN),
        .BLUE_G_MARGIN (BLUE_G_MARGIN)
    ) U_RGB_DEC (
        // Existing RG_detect interface - keep as-is
        .clk             (clk),
        .rst             (rst),
        .i_rgb           (w_RGB),
        .i_x_pixel       (w_x_pixel),
        .i_y_pixel       (w_y_pixel),
        .de              (w_de),
        .xy_control_ready(w_xy_control_ready),
        .xy_control_valid(w_xy_control_valid),
        .o_pixel         (w_pixel),
        .o_stick_x_pixel (w_stick_x_pixel),
        .o_stick_y_pixel (w_stick_y_pixel),
        // output logic [ 9:0] o_hand_x_pixel,
        .o_hand_y_pixel  (w_hand_y_pixel),
        .o_vsync         (w_pixel_dec_sync),
        // New VGA filter path - uppercase naming
        .SW_RED          (SW_RED),
        .SW_GREEN        (SW_GREEN),
        .SW_BLUE         (SW_BLUE),
        .H_SYNC_IN       (w_VGA_H_SYNC),
        .V_SYNC_IN       (w_VGA_V_SYNC),
        // 영상 출력부
        .H_SYNC          (H_SYNC),
        .V_SYNC          (V_SYNC),
        .RGB             (RGB)
    );

    game_logic U_GAME_LOGIC (
        .clk                  (clk),
        .rst                  (rst),
        // from rg_detect
        .i_stick_x_pixel      (w_stick_x_pixel),
        .i_stick_y_pixel      (w_stick_y_pixel),
        // input  logic [ 9:0] i_hand_x_pixel,
        .i_hand_y_pixel       (w_hand_y_pixel),
        .i_vsync              (w_pixel_dec_sync),
        // for uart_wrapper signal
        // volume value data
        .volume_uart_ready    (w_volume_uart_ready),
        .volume_uart_valid    (w_volume_uart_valid),
        .o_volume_level       (w_volume_level),
        // speed bpm data
        .stick_control_ready  (w_stick_control_ready),
        .stick_control_valid  (w_stick_control_valid),
        .o_speed              (w_speed),
        // game score data
        .score_control_ready  (w_score_control_ready),
        .score_control_valid  (w_score_control_valid),
        .o_score              (w_score),
        // game state data
        .game_control_ready   (w_game_control_ready),
        .game_control_valid   (w_game_control_valid),
        .o_game_state         (w_game_state),
        // gatten state data
        .pattern_control_ready(w_pattern_control_ready),
        .pattern_control_valid(w_pattern_control_valid),
        .o_pattern_state      (w_pattern_state),
        // from pc to uart rx data
        .i_pc_state           (w_rx_data[6:4]),
        .i_pc_song            (w_rx_data[2:0])
    );

    uart_wrapper U_UART (
        .clk                  (clk),
        .rst                  (rst),
        .pixel_dec_sync       (w_pixel_dec_sync),
        .volume_uart_ready    (w_volume_uart_ready),
        .volume_uart_valid    (w_volume_uart_valid),
        .i_volume_level       (w_volume_level),
        .xy_uart_ready        (w_xy_control_ready),
        .xy_uart_valid        (w_xy_control_valid),
        .i_pixel              (w_pixel),
        .stick_control_ready  (w_stick_control_ready),
        .stick_control_valid  (w_stick_control_valid),
        .i_speed              (w_speed),
        .score_control_ready  (w_score_control_ready),
        .score_control_valid  (w_score_control_valid),
        .i_score              (w_score),
        .game_control_ready   (w_game_control_ready),
        .game_control_valid   (w_game_control_valid),
        .i_game_state         (w_game_state),
        .pattern_control_ready(w_pattern_control_ready),
        .pattern_control_valid(w_pattern_control_valid),
        .i_pattern_state      (w_pattern_state),
        // to anothor top module
        .o_rx_data            (w_rx_data),
        // uart
        .tx                   (tx),
        .rx                   (rx)
    );

endmodule
