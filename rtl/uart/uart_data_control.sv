`timescale 1ns / 1ps

module uart_data_control (
    input  logic        clk,
    input  logic        rst,
    input  logic        tx_sync,
    input  logic        uart_data_control_uart_ready,
    output logic        uart_data_control_uart_valid,
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
    output logic [63:0] o_tx_data,
    input  logic [ 7:0] i_rx_data,
    output logic [ 7:0] o_rx_data
);
    logic [63:0] r_tx_data;

    localparam GAME_FSM_BW = 2;
    localparam XY_DEC_BW = 40;
    localparam PATTERN_BW = 3;
    localparam VOL_BW = 7;
    localparam SPEED_BW = 8;
    localparam SCORE_BW = 4;
    localparam TX_DATA_BW = GAME_FSM_BW + XY_DEC_BW + SPEED_BW + VOL_BW + PATTERN_BW + SCORE_BW;

    assign o_tx_data = r_tx_data;
    assign o_rx_data = i_rx_data;

    // game_fsm : 맨 위 비트
    localparam GAME_FSM_MSB = TX_DATA_BW - 1;  // 63
    localparam GAME_FSM_LSB = GAME_FSM_MSB - (GAME_FSM_BW - 1);  // 62

    // xy_dec : game_fsm 바로 아래
    localparam XY_DEC_MSB = GAME_FSM_LSB - 1;  // 61
    localparam XY_DEC_LSB = XY_DEC_MSB - (XY_DEC_BW - 1);  // 22

    // pattern : xy_dec 바로 아래
    localparam PATTERN_MSB = XY_DEC_LSB - 1;  // 21
    localparam PATTERN_LSB = PATTERN_MSB - (PATTERN_BW - 1);  // 19

    // vol : pattern 바로 아래
    localparam VOL_MSB = PATTERN_LSB - 1;  // 18
    localparam VOL_LSB = VOL_MSB - (VOL_BW - 1);  // 12

    // speed : vol 바로 아래
    localparam SPEED_MSB = VOL_LSB - 1;  // 11
    localparam SPEED_LSB = SPEED_MSB - (SPEED_BW - 1);  // 4

    // score : 맨 아래 비트
    localparam SCORE_MSB = SPEED_LSB - 1;  // 3
    localparam SCORE_LSB = SCORE_MSB - (SCORE_BW - 1);  // 0



    assign game_control_ready    = ~uart_data_control_uart_valid;
    assign xy_uart_ready         = ~uart_data_control_uart_valid;
    assign pattern_control_ready = ~uart_data_control_uart_valid;
    assign volume_uart_ready     = ~uart_data_control_uart_valid;
    assign stick_control_ready   = ~uart_data_control_uart_valid;
    assign score_control_ready   = ~uart_data_control_uart_valid;

    // game_fsm handshack input  logic [ 1:0] i_game_state,
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tx_data[GAME_FSM_MSB:GAME_FSM_LSB] <= 0;
        end else if (game_control_valid && game_control_ready) begin
            r_tx_data[GAME_FSM_MSB:GAME_FSM_LSB] <= i_game_state;
        end
    end

    // xy_dection handshack
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tx_data[XY_DEC_MSB:XY_DEC_LSB] <= 0;
        end else if (xy_uart_valid && xy_uart_ready) begin
            r_tx_data[XY_DEC_MSB:XY_DEC_LSB] <= i_pixel;
        end
    end

    // stick_speed_calc handshack
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tx_data[SPEED_MSB:SPEED_LSB] <= 0;
        end else if (stick_control_valid && stick_control_ready) begin
            r_tx_data[SPEED_MSB:SPEED_LSB] <= i_speed;
        end
    end

    // volum_ctrl handshack
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tx_data[VOL_MSB:VOL_LSB] <= 0;
        end else if (volume_uart_valid && volume_uart_ready) begin
            r_tx_data[VOL_MSB:VOL_LSB] <= i_volume_level;
        end
    end

    // pattern_stick handshack
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tx_data[PATTERN_MSB:PATTERN_LSB] <= 0;
        end else if (pattern_control_valid && pattern_control_ready) begin
            r_tx_data[PATTERN_MSB:PATTERN_LSB] <= i_pattern_state;
        end
    end

    // game_score handshack
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tx_data[SCORE_MSB:SCORE_LSB] <= 0;
        end else if (score_control_valid && score_control_ready) begin
            r_tx_data[SCORE_MSB:SCORE_LSB] <= i_score;
        end
    end

    // uart tx handshack
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            uart_data_control_uart_valid <= 0;
        end else begin
            if (uart_data_control_uart_valid && uart_data_control_uart_ready) begin
                uart_data_control_uart_valid <= 0;
            end else if (tx_sync) begin
                uart_data_control_uart_valid <= 1;
            end else begin
                uart_data_control_uart_valid <= uart_data_control_uart_valid;
            end
        end
    end


endmodule

