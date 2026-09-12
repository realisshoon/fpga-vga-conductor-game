interface rg_detect_if (
    input logic clk
);

    logic        rst;

    logic [11:0] i_rgb;
    logic [ 9:0] i_x_pixel;
    logic [ 9:0] i_y_pixel;
    logic        de;
    logic        xy_control_ready;

    logic [ 9:0] o_stick_x_pixel;
    logic [ 9:0] o_stick_y_pixel;
    logic [ 9:0] o_hand_x_pixel;
    logic [ 9:0] o_hand_y_pixel;
    logic        o_vsync;
    logic [39:0] o_pixel;
    logic        xy_control_valid;

    clocking drv_cb @(negedge clk);
        output i_rgb;
        output i_x_pixel;
        output i_y_pixel;
        output de;
        output xy_control_ready;

        input o_stick_x_pixel;
        input o_stick_y_pixel;
        input o_hand_x_pixel;
        input o_hand_y_pixel;
        input o_vsync;
        input o_pixel;
        input xy_control_valid;
    endclocking

    clocking mon_cb @(negedge clk);
        input rst;

        input i_rgb;
        input i_x_pixel;
        input i_y_pixel;
        input de;
        input xy_control_ready;

        input o_stick_x_pixel;
        input o_stick_y_pixel;
        input o_hand_x_pixel;
        input o_hand_y_pixel;
        input o_vsync;
        input o_pixel;
        input xy_control_valid;
    endclocking

endinterface

