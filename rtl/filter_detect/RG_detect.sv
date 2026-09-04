`timescale 1ns / 1ps

module RG_detect #(
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
    // Existing RG_detect interface - keep as-is
    input logic        clk,
    input logic        rst,
    input logic [11:0] i_rgb,
    input logic [ 9:0] i_x_pixel,
    input logic [ 9:0] i_y_pixel,
    input logic        de,
    input logic        xy_control_ready,

    output logic [ 9:0] o_stick_x_pixel,
    output logic [ 9:0] o_stick_y_pixel,
    output logic [ 9:0] o_hand_x_pixel,
    output logic [ 9:0] o_hand_y_pixel,
    output logic        o_vsync,
    output logic [39:0] o_pixel,
    output logic        xy_control_valid,

    // New VGA filter path - uppercase naming
    input logic SW_RED,
    input logic SW_GREEN,
    input logic SW_BLUE,
    input logic H_SYNC_IN,
    input logic V_SYNC_IN,

    // 영상 출력부
    output logic        H_SYNC,
    output logic        V_SYNC,
    output logic [11:0] RGB
);

    // Internal signals stay lowercase
    logic       red_detect;
    logic       green_detect;
    logic [9:0] detect_x_pixel;
    logic [9:0] detect_y_pixel;

    rgb_filter #(
        .RED_MIN     (RED_MIN),
        .RED_G_MARGIN(RED_G_MARGIN),
        .RED_B_MARGIN(RED_B_MARGIN),

        .GREEN_MIN     (GREEN_MIN),
        .GREEN_R_MARGIN(GREEN_R_MARGIN),
        .GREEN_B_MARGIN(GREEN_B_MARGIN),

        .BLUE_MIN     (BLUE_MIN),
        .BLUE_R_MARGIN(BLUE_R_MARGIN),
        .BLUE_G_MARGIN(BLUE_G_MARGIN)
    ) U_RGB_FILTER (
        .clk(clk),
        .rst(rst),

        // Existing detection path
        .i_rgb           (i_rgb),
        .i_x_pixel       (i_x_pixel),
        .i_y_pixel       (i_y_pixel),
        .de              (de),
        .o_red_detect    (red_detect),
        .o_green_detect  (green_detect),
        .o_x_detect_pixel(detect_x_pixel),
        .o_y_detect_pixel(detect_y_pixel),

        // New VGA filter path
        .SW_RED   (SW_RED),
        .SW_GREEN (SW_GREEN),
        .SW_BLUE  (SW_BLUE),
        .H_SYNC_IN(H_SYNC_IN),
        .V_SYNC_IN(V_SYNC_IN),
        .H_SYNC   (H_SYNC),
        .V_SYNC   (V_SYNC),
        .RGB      (RGB)
    );

    xy_detection U_XY_DETECTION (
        .clk             (clk),
        .rst             (rst),
        .i_red_detect    (red_detect),
        .i_green_detect  (green_detect),
        .i_x_detect_pixel(detect_x_pixel),
        .i_y_detect_pixel(detect_y_pixel),
        .xy_control_ready(xy_control_ready),
        .o_stick_x_pixel (o_stick_x_pixel),
        .o_stick_y_pixel (o_stick_y_pixel),
        .o_hand_x_pixel  (o_hand_x_pixel),
        .o_hand_y_pixel  (o_hand_y_pixel),
        .o_vsync         (o_vsync),
        .o_pixel         (o_pixel),
        .xy_control_valid(xy_control_valid)
    );

endmodule
