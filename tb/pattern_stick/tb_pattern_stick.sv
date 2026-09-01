`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 14:46:25
// Design Name: 
// Module Name: tb_pattern_stick
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_pattern_stick ();

    logic       clk;
    logic       rst;
    logic       game_start;
    logic       game_stop;
    logic [9:0] i_stick_x_pixel;
    logic [9:0] i_stick_y_pixel;
    logic       i_vsync;
    logic       pattern_control_ready;
    logic       pattern_control_valid;
    logic [2:0] pattern_state;
    logic       pattern_tick;


    pattern_stick U_PATTERN_STICK (.*);

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        clk = 0;
        #30;
        rst = 0;
        @(posedge clk);
        game_start = 1;

        @(posedge clk);
        game_start = 0;

        @(posedge clk);
        @(posedge clk);
        pattern_control_ready = 1;

        @(posedge clk);
        pattern_control_ready = 0;

        i_stick_x_pixel = 160;
        i_stick_y_pixel = 195;

        @(posedge clk);
        i_vsync = 1;
        @(posedge clk);
        i_vsync = 0;
        i_stick_x_pixel = 100;
        i_stick_y_pixel = 135;
        pattern_control_ready = 1;
        @(posedge clk);

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        game_stop = 1;

        @(posedge clk);
        game_stop = 0;




    end



endmodule
