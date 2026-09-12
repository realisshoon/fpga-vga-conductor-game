`timescale 1ns / 1ps

module color_xy_pipeline_top #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW    = 16,
    parameter AW    = $clog2(IMG_H * IMG_W)
) (
    input logic clk,
    input logic rst,

    input logic [9:0] i_x_pixel,
    input logic [9:0] i_y_pixel,
    input logic       de,

    input logic xy_control_ready,

    output logic [9:0] o_stick_x_pixel,
    output logic [9:0] o_stick_y_pixel,
    output logic [9:0] o_hand_x_pixel,
    output logic [9:0] o_hand_y_pixel,

    output logic        o_vsync,
    output logic [39:0] o_pixel,
    output logic        xy_control_valid,

    // Debug
    output logic [AW-1:0] o_raddr,
    output logic [DW-1:0] o_rdata,
    output logic [  11:0] o_rgb
);
    logic [AW-1:0] rAddr;
    logic [DW-1:0] rData;
    logic [  11:0] qvga_rgb;

    frame_buffer #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .DW   (DW),
        .AW   (AW)
    ) U_FRAME_BUFFER (
        .wclk (clk),
        .we   (1'b0),
        .wAddr(0),
        .wData(0),
        .rclk (clk),
        .rAddr(rAddr),
        .rData(rData)
    );
    rom_reader U_ROM_READER (
        .clk      (clk),
        .rst      (rst),
        .de       (de),
        .sw_invert(1'b0),
        .x_pixel  (i_x_pixel),
        .y_pixel  (i_y_pixel),
        .addr     (rAddr),
        .px_data  (rData),
        .o_rgb    (qvga_rgb)
    );

    color_xy_top U_COLOR_XY_TOP (
        .clk(clk),
        .rst(rst),

        .i_rgb    (qvga_rgb),
        .i_x_pixel(i_x_pixel),
        .i_y_pixel(i_y_pixel),
        .de       (de),

        .xy_control_ready(xy_control_ready),

        .o_stick_x_pixel(o_stick_x_pixel),
        .o_stick_y_pixel(o_stick_y_pixel),

        .o_hand_x_pixel(o_hand_x_pixel),
        .o_hand_y_pixel(o_hand_y_pixel),

        .o_vsync(o_vsync),
        .o_pixel(o_pixel),

        .xy_control_valid(xy_control_valid)
    );


    // Debug
    assign o_raddr = rAddr;
    assign o_rdata = rData;
    assign o_rgb   = qvga_rgb;

endmodule
