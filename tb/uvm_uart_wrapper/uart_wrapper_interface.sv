interface uart_wrapper_interface (
    input logic clk,
    input logic rst,
    input logic pixel_dec_sync
);
    logic        volume_uart_ready;
    logic [ 6:0] i_volume_level;
    logic        volume_uart_valid;
    logic        xy_uart_ready;
    logic [39:0] i_pixel;
    logic        xy_uart_valid;
    logic        stick_control_ready;
    logic [ 7:0] i_speed;
    logic        stick_control_valid;
    logic        score_control_ready;
    logic [ 3:0] i_score;
    logic        score_control_valid;
    logic        game_control_ready;
    logic [ 1:0] i_game_state;
    logic        game_control_valid;
    logic        pattern_control_ready;
    logic        pattern_control_valid;
    logic [ 2:0] i_pattern_state;
    // to anothor top module
    logic [ 7:0] o_rx_data;
    logic [ 7:0] expected_rx_data;
    logic rx_done;
    // uart
    logic        tx;
    logic        rx;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input pixel_dec_sync;

        input volume_uart_ready;
        output i_volume_level;
        output volume_uart_valid;
        input xy_uart_ready;
        output i_pixel;
        output xy_uart_valid;
        input stick_control_ready;
        output i_speed;
        output stick_control_valid;
        input score_control_ready;
        output i_score;
        output score_control_valid;
        input game_control_ready;
        output i_game_state;
        output game_control_valid;
        input pattern_control_ready;
        output pattern_control_valid;
        output i_pattern_state;
        input o_rx_data;
        input tx;
        output rx;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0.001;
        input pixel_dec_sync;

        input volume_uart_ready;
        input i_volume_level;
        input volume_uart_valid;
        input xy_uart_ready;
        input i_pixel;
        input xy_uart_valid;
        input stick_control_ready;
        input i_speed;
        input stick_control_valid;
        input score_control_ready;
        input i_score;
        input score_control_valid;
        input game_control_ready;
        input i_game_state;
        input game_control_valid;
        input pattern_control_ready;
        input pattern_control_valid;
        input i_pattern_state;
        input o_rx_data;
        input tx;
        input rx;
        input rx_done;
    endclocking

    // Handshake rule
    property p_field_data_valid_deassert(logic valid, logic ready);
        @(posedge clk) disable iff (rst) (valid && ready) |=> !valid;
    endproperty

    a_volume_valid_deassert :
    assert property (p_field_data_valid_deassert(volume_uart_valid, volume_uart_ready));

    a_pixel_valid_deassert :
    assert property (p_field_data_valid_deassert(xy_uart_valid, xy_uart_ready));

    a_speed_valid_deassert :
    assert property (p_field_data_valid_deassert(
        stick_control_valid, stick_control_ready
    ));

    a_score_valid_deassert :
    assert property (p_field_data_valid_deassert(
        score_control_valid, score_control_ready
    ));

    a_game_valid_ready_deassert :
    assert property (p_field_data_valid_deassert(game_control_valid, game_control_ready));

    a_pattern_state_valid_deassert :
    assert property (p_field_data_valid_deassert(
        pattern_control_valid, pattern_control_ready
    ));
endinterface
