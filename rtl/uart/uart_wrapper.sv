`timescale 1ns / 1ps

module uart_wrapper (
    input  logic        clk,
    input  logic        rst,
    input  logic        pixel_dec_sync,
    output logic        volume_uart_ready,
    input  logic [ 6:0] i_volume_level,
    input  logic        volume_uart_valid,
    output logic        xy_uart_ready,
    input  logic [39:0] i_pixel,
    input  logic        xy_uart_valid,
    output logic        stick_control_ready,
    input  logic [ 7:0] i_speed,
    input  logic        stick_control_valid,
    output logic        score_control_ready,
    input  logic [ 3:0] i_score,
    input  logic        score_control_valid,
    output logic        game_control_ready,
    input  logic [ 1:0] i_game_state,
    input  logic        game_control_valid,
    output logic        pattern_control_ready,
    input  logic        pattern_control_valid,
    input  logic [ 2:0] i_pattern_state,

    // to anothor top module
    output logic [7:0] o_rx_data,

    // uart
    output logic tx,
    input  logic rx
);
    localparam BAUD_RATE = 115_200;
    localparam SAMPLE = 16;
    localparam DEPTH = 8;
    localparam BW = 8;
    // uart tx handshake signal
    logic                uart_data_control_uart_ready;
    logic                uart_data_control_uart_valid;

    // uart wire
    logic [DEPTH*BW-1:0] w_tx_data;
    logic [      BW-1:0] w_rx_data;
    // sync
    logic                tx_sync;

    uart_data_control U_DATA_CONTROL (
        .clk                         (clk),
        .rst                         (rst),
        .tx_sync                     (tx_sync),
        .uart_data_control_uart_ready(uart_data_control_uart_ready),
        .uart_data_control_uart_valid(uart_data_control_uart_valid),
        .volume_uart_ready           (volume_uart_ready),
        .i_volume_level              (i_volume_level),
        .volume_uart_valid           (volume_uart_valid),
        .xy_uart_ready               (xy_uart_ready),
        .i_pixel                     (i_pixel),
        .xy_uart_valid               (xy_uart_valid),
        .stick_control_ready         (stick_control_ready),
        .i_speed                     (i_speed),
        .stick_control_valid         (stick_control_valid),
        .score_control_ready         (score_control_ready),
        .i_score                     (i_score),
        .score_control_valid         (score_control_valid),
        .game_control_ready          (game_control_ready),
        .i_game_state                (i_game_state),
        .game_control_valid          (game_control_valid),
        .pattern_control_ready       (pattern_control_ready),
        .pattern_control_valid       (pattern_control_valid),
        .i_pattern_state             (i_pattern_state),
        .o_tx_data                   (w_tx_data),
        .i_rx_data                   (w_rx_data),
        .o_rx_data                   (o_rx_data)
    );

    uart #(
        .BAUD_RATE(BAUD_RATE),
        .SAMPLE   (SAMPLE),
        .DEPTH    (DEPTH),
        .BW       (BW)
    ) U_UART (
        .clk                         (clk),
        .rst                         (rst),
        .tx                          (tx),
        .rx                          (rx),
        .uart_data_control_uart_ready(uart_data_control_uart_ready),
        .uart_data_control_uart_valid(uart_data_control_uart_valid),
        .i_tx_data                   (w_tx_data),
        .o_rx_data                   (w_rx_data)
    );

    sync_delay U_SYNC_DELAY (
        .clk           (clk),
        .rst           (rst),
        .pixel_dec_sync(pixel_dec_sync),
        .tx_sync       (tx_sync)
    );

endmodule


