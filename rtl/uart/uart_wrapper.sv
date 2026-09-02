`timescale 1ns / 1ps

module uart_wrapper (
    input logic clk,
    input logic rst,
    input logic pixel_dec_sync,

    output logic volume_uart_ready,
    input logic [2:0] i_volume_level,
    input logic volume_uart_valid,

    output logic xy_uart_ready,
    output logic [39:0] i_pixel,
    input logic xy_uart_valid,

    output logic stick_control_ready,
    input logic [27:0] i_speed,
    input logic stick_control_valid,

    output logic score_control_ready,
    input  logic i_score,
    output logic score_control_vaild,

    output logic game_control_ready,
    input  logic i_game_state,
    input  logic game_control_vaild,

    output logic pattern_control_ready,
    input  logic pattern_control_valid,
    input  logic i_pattern_state,

    // data in/out

    // uart
    output logic tx,
    input  logic rx
);
    localparam BAUD_RATE = 115_200;
    localparam SAMPLE = 16;
    localparam DEPTH = 8;
    localparam BW = 8;
    // uart handshake signal
    logic                uart_data_control_uart_ready;
    logic                uart_data_control_uart_valid;
    logic                uart_uart_data_control_ready;
    logic                uart_uart_data_control_valid;

    // uart wire
    logic [DEPTH*BW-1:0] i_tx_data;
    logic [      BW-1:0] o_rx_data;
    // sync
    logic                tx_sync;


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
        .i_tx_data                   (i_tx_data),
        .o_rx_data                   (o_rx_data)
    );

    sync_delay U_SYNC_DELAY (
        .clk           (clk),
        .rst           (rst),
        .pixel_dec_sync(pixel_dec_sync),
        .tx_sync       (tx_sync)
    );

endmodule

