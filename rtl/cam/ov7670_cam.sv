`timescale 1ns / 1ps

module ov7670_cam #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 16,
    parameter AW = $clog2(IMG_H * IMG_W)
) (
    // OV7670 signal
    output logic       xclk,
    input  logic       pclk,
    input  logic       cam_href,
    input  logic       cam_vsync,
    input  logic [7:0] cam_data,

    // VGA controller signal
    input logic clk,
    input logic rst,
    input logic sw_mode,
    input logic sw_invert,

    // // New VGA filter control - uppercase naming
    // input logic SW_RED,
    // input logic SW_GREEN,
    // input logic SW_BLUE,

    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,


    // OV7670 setup port
    output logic scl,
    inout  logic sda,

    output logic        VGA_H_SYNC,
    output logic        VGA_V_SYNC,
    output logic        VGA_DE,
    output logic [ 9:0] VGA_X_PIXEL,
    output logic [ 9:0] VGA_Y_PIXEL,
    output logic [11:0] VGA_RGB

);

    logic we;
    logic [AW-1:0] wAddr, rAddr;
    logic [DW-1:0] wData, rData;


    logic          de;
    logic          w_h_sync;
    logic          w_v_sync;
    logic [   9:0] x_pixel;
    logic [   9:0] y_pixel;

    logic [  11:0] w_rgb;
    logic [  11:0] qvga_rgb;
    logic [  11:0] upscale_rgb;

    logic [AW-1:0] qvga_addr;
    logic [AW-1:0] upscale_addr;

    // logic          FILTER_H_SYNC;
    // logic          FILTER_V_SYNC;
    // logic [  11:0] FILTER_RGB;

    // RG_detect results for later downstream integration
    // logic [   9:0] stick_x_pixel;
    // logic [   9:0] stick_y_pixel;
    // logic [   9:0] hand_x_pixel;
    // logic [   9:0] hand_y_pixel;
    // logic          rg_vsync;
    // logic [  39:0] rg_pixel;
    // logic          xy_control_valid;


    assign rAddr = (sw_mode) ? upscale_addr : qvga_addr;
    assign w_rgb = (sw_mode) ? upscale_rgb : qvga_rgb;

    SCCB_Setup_controller U_OV_SETUP_CTRL (
        .clk(clk),
        .rst(rst),
        .scl(scl),
        .sda(sda)
    );

    ov7670_mem_controller U_OV7670_MEM_CONTROLLER (
        .rst      (rst),
        .pclk     (pclk),
        .cam_href (cam_href),
        .cam_vsync(cam_vsync),
        .cam_data (cam_data),
        .we       (we),
        .wAddr    (wAddr),
        .wData    (wData)
    );


    vga_decoder U_VGA_DECODER (
        .clk    (clk),
        .rst    (rst),
        .xclk   (xclk),
        .h_sync (w_h_sync),
        .v_sync (w_v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de     (de)
    );


    frame_buffer U_FRAME_BUFFER (
        .wclk (pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (clk),
        .rAddr(rAddr),
        .rData(rData)
    );


    rom_reader U_ROM_READER (
        .clk      (clk),
        .rst      (rst),
        .de       (de),
        .sw_invert(sw_invert),
        .x_pixel  (x_pixel),
        .y_pixel  (y_pixel),
        .addr     (qvga_addr),
        .px_data  (rData),
        .o_rgb    (qvga_rgb)
    );


    rom_reader_upscale U_ROM_READER_UPSCALE (
        .clk      (clk),
        .rst      (rst),
        .de       (de),
        .sw_invert(sw_invert),
        .x_pixel  (x_pixel),
        .y_pixel  (y_pixel),
        .addr     (upscale_addr),
        .px_data  (rData),
        .o_rgb    (upscale_rgb)
    );


    vga_outreg U_VGA_OUTREG (
        .clk(clk),
        .rst(rst),

        .H_SYNC_IN (w_h_sync),
        .V_SYNC_IN (w_v_sync),
        .DE_IN     (de),
        .X_PIXEL_IN(x_pixel),
        .Y_PIXEL_IN(y_pixel),
        .RGB_IN    (w_rgb),

        .H_SYNC (VGA_H_SYNC),
        .V_SYNC (VGA_V_SYNC),
        .DE     (VGA_DE),
        .X_PIXEL(VGA_X_PIXEL),
        .Y_PIXEL(VGA_Y_PIXEL),
        .RGB    (VGA_RGB)
    );

    // RG_detect U_RG_DETECT (
    //     .clk(clk),
    //     .rst(rst),

    //     // Existing RG_detect path
    //     .i_rgb           (VGA_RGB),
    //     .i_x_pixel       (VGA_X_PIXEL),
    //     .i_y_pixel       (VGA_Y_PIXEL),
    //     .de              (VGA_DE),
    //     .xy_control_ready(1'b1),

    //     .o_stick_x_pixel (stick_x_pixel),
    //     .o_stick_y_pixel (stick_y_pixel),
    //     .o_hand_x_pixel  (hand_x_pixel),
    //     .o_hand_y_pixel  (hand_y_pixel),
    //     .o_vsync         (rg_vsync),
    //     .o_pixel         (rg_pixel),
    //     .xy_control_valid(xy_control_valid),

    //     // New VGA filter path
    //     .SW_RED   (SW_RED),
    //     .SW_GREEN (SW_GREEN),
    //     .SW_BLUE  (SW_BLUE),
    //     .H_SYNC_IN(VGA_H_SYNC),
    //     .V_SYNC_IN(VGA_V_SYNC),
    //     .H_SYNC   (FILTER_H_SYNC),
    //     .V_SYNC   (FILTER_V_SYNC),
    //     .RGB      (FILTER_RGB)
    // );


    // assign h_sync     = FILTER_H_SYNC;
    // assign v_sync     = FILTER_V_SYNC;
    // assign port_red   = FILTER_RGB[11:8];
    // assign port_green = FILTER_RGB[7:4];
    // assign port_blue  = FILTER_RGB[3:0];

endmodule



module vga_outreg (
    input logic clk,
    input logic rst,

    // VGA stream input - uppercase naming
    input logic        H_SYNC_IN,
    input logic        V_SYNC_IN,
    input logic        DE_IN,
    input logic [ 9:0] X_PIXEL_IN,
    input logic [ 9:0] Y_PIXEL_IN,
    input logic [11:0] RGB_IN,

    // Aligned VGA stream output - uppercase naming
    output logic        H_SYNC,
    output logic        V_SYNC,
    output logic        DE,
    output logic [ 9:0] X_PIXEL,
    output logic [ 9:0] Y_PIXEL,
    output logic [11:0] RGB
);

    // Internal pipeline signals stay lowercase
    logic       h_sync_d1;
    logic       v_sync_d1;
    logic       de_d1;
    logic [9:0] x_pixel_d1;
    logic [9:0] y_pixel_d1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            h_sync_d1  <= 1'b1;
            v_sync_d1  <= 1'b1;
            de_d1      <= 1'b0;
            x_pixel_d1 <= 10'd0;
            y_pixel_d1 <= 10'd0;
        end else begin
            h_sync_d1  <= H_SYNC_IN;
            v_sync_d1  <= V_SYNC_IN;
            de_d1      <= DE_IN;
            x_pixel_d1 <= X_PIXEL_IN;
            y_pixel_d1 <= Y_PIXEL_IN;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            H_SYNC  <= 1'b1;
            V_SYNC  <= 1'b1;
            DE      <= 1'b0;
            X_PIXEL <= 10'd0;
            Y_PIXEL <= 10'd0;
            RGB     <= 12'h000;
        end else begin
            H_SYNC  <= h_sync_d1;
            V_SYNC  <= v_sync_d1;
            DE      <= de_d1;
            X_PIXEL <= x_pixel_d1;
            Y_PIXEL <= y_pixel_d1;
            RGB     <= RGB_IN;
        end
    end

endmodule
