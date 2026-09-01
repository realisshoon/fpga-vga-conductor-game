`timescale 1ns / 1ps

module top_ov_7670 #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 16,
    parameter AW = $clog2(IMG_H * IMG_W)
) (
    // ov7670 signal
    output logic       xclk,
    input  logic       pclk,
    input  logic       cam_href,
    input  logic       cam_vsync,
    input  logic [7:0] cam_data,

    // VGA controller sig
    input  logic       clk,
    input  logic       reset,
    input  logic       sw_mode,
    // input  logic       sw_gray,
    // input  logic       sw_binary,
    // input  logic       sw_invert,
    // input  logic [3:0] sw_th,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,

    // OB7670 setup port
    output logic scl,
    inout  logic sda
);
    // Frame Buffer
    logic we;
    logic [AW-1:0] wAddr, rAddr;
    logic [DW-1:0] wData, rData;

    // VGA
    logic w_h_sync, w_h_sync2, w_h_sync3;
    logic w_v_sync, w_v_sync2, w_v_sync3;
    logic [9:0] x_pixel, y_pixel;
    logic de;
    logic [11:0] g_rgb, r_rgb, w_rgb, qvga_rgb, upscale_rgb, gray_rgb;
    logic [AW-1:0] qvga_addr, upscale_addr;
    logic [DW-1:0] px_data;

    // MUX
    assign rAddr = (sw_mode) ? upscale_addr : qvga_addr;
    assign w_rgb = (sw_mode) ? upscale_rgb : qvga_rgb;

    // OV7670 setup
    SCCB_Setup_controller U_OV_SETUP_CTRL (
        .clk(clk),
        .rst(reset),
        .scl(scl),
        .sda(sda)
    );

    // Camera Controller
    ov7670_mem_controller U_OV7670_MEM_CONTROLLER (
        .reset    (reset),
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
        .reset  (reset),
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
        .reset    (reset),
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
        .reset    (reset),
        .de       (de),
        .sw_invert(sw_invert),
        .x_pixel  (x_pixel),
        .y_pixel  (y_pixel),
        .addr     (upscale_addr),
        .px_data  (rData),
        .o_rgb    (upscale_rgb)
    );
    vga_outreg U_VGA_OUTREG (
        .clk     (clk),
        .reset   (reset),
        .i_h_sync(w_h_sync),
        .i_v_sync(w_v_sync),
        .i_rgb   (w_rgb),
        .o_h_sync(h_sync),
        .o_v_sync(v_sync),
        .o_rgb   ({port_red, port_green, port_blue})
    );
    // vga_outreg U_VGA_OUTREG (
    //     .clk     (clk),
    //     .reset   (reset),
    //     .i_h_sync(w_h_sync),
    //     .i_v_sync(w_v_sync),
    //     .i_rgb   (w_rgb),
    //     .o_h_sync(w_h_sync2),
    //     .o_v_sync(w_v_sync2),
    //     .o_rgb   (r_rgb)
    // );
    // gray_filter U_GRAY_FILTER (
    //     .clk     (clk),
    //     .reset   (reset),
    //     .sw_gray (sw_gray),
    //     .i_h_sync(w_h_sync2),
    //     .i_v_sync(w_v_sync2),
    //     .i_rgb   (r_rgb),
    //     .o_h_sync(w_h_sync3),
    //     .o_v_sync(w_v_sync3),
    //     .o_rgb   (g_rgb)
    // );
    // binary_filter U_BINARY_FILTER (
    //     .clk      (clk),
    //     .reset    (reset),
    //     .sw_binary(sw_binary),
    //     .sw_invert(sw_invert),
    //     .sw_th    (sw_th),
    //     .i_rgb    (g_rgb),
    //     .i_h_sync (w_h_sync3),
    //     .i_v_sync (w_v_sync3),
    //     .o_rgb    ({port_red, port_green, port_blue}),
    //     .o_h_sync (h_sync),
    //     .o_v_sync (v_sync)
    // );
endmodule

module vga_outreg (
    input  logic        clk,
    input  logic        reset,
    input  logic        i_h_sync,
    input  logic        i_v_sync,
    input  logic [11:0] i_rgb,
    output logic        o_h_sync,
    output logic        o_v_sync,
    output logic [11:0] o_rgb
);

    logic r_h_sync, r_v_sync;
    logic [11:0] r_rgb;

    assign o_h_sync = r_h_sync;
    assign o_v_sync = r_v_sync;
    assign o_rgb    = r_rgb;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_h_sync <= 1'b1;
            r_v_sync <= 1'b1;
            r_rgb    <= 0;
        end else begin
            r_h_sync <= i_h_sync;
            r_v_sync <= i_v_sync;
            r_rgb    <= i_rgb;
        end
    end
endmodule

