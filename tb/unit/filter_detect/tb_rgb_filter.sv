`timescale 1ns / 1ps

module tb_rgb_filter;

    logic        clk;
    logic        rst;
    logic [11:0] i_rgb;
    logic [ 9:0] i_x_pixel;
    logic [ 9:0] i_y_pixel;
    logic        de;
    logic        o_red_detect;
    logic        o_green_detect;
    logic [ 9:0] o_x_detect_pixel;
    logic [ 9:0] o_y_detect_pixel;

    rgb_filter DUT (
        .clk             (clk),
        .rst             (rst),
        .i_rgb           (i_rgb),
        .i_x_pixel       (i_x_pixel),
        .i_y_pixel       (i_y_pixel),
        .de              (de),
        .o_red_detect    (o_red_detect),
        .o_green_detect  (o_green_detect),
        .o_x_detect_pixel(o_x_detect_pixel),
        .o_y_detect_pixel(o_y_detect_pixel)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst       = 1'b1;
        i_rgb     = 12'h000;
        i_x_pixel = 10'd0;
        i_y_pixel = 10'd0;
        de        = 1'b0;

        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        // red clear
        // RGB = 12 4 3
        @(negedge clk);

        i_rgb     = 12'hC43;
        i_x_pixel = 10'd100;
        i_y_pixel = 10'd50;
        de        = 1'b1;

        @(posedge clk);
        #1;

        if ((o_red_detect == 1'b1) &&
            (o_green_detect == 1'b0) &&
            (o_x_detect_pixel == 10'd100) &&
            (o_y_detect_pixel == 10'd50)) begin

            $display("[PASS] CLEAR RED");

        end else begin

            $display("[FAIL] CLEAR RED");
        end

        // green clear
        // RGB = 3 11 4

        @(negedge clk);

        i_rgb     = 12'h3B4;
        i_x_pixel = 10'd200;
        i_y_pixel = 10'd100;
        de        = 1'b1;

        @(posedge clk);
        #1;

        if ((o_red_detect == 1'b0) &&
            (o_green_detect == 1'b1) &&
            (o_x_detect_pixel == 10'd200) &&
            (o_y_detect_pixel == 10'd100)) begin

            $display("[PASS] CLEAR GREEN");

        end else begin

            $display("[FAIL] CLEAR GREEN");
        end

        // DE Off
        @(negedge clk);

        i_rgb     = 12'hF00;
        i_x_pixel = 10'd300;
        i_y_pixel = 10'd150;
        de        = 1'b0;

        @(posedge clk);
        #1;

        if ((o_red_detect == 1'b0) && (o_green_detect == 1'b0)) begin

            $display("[PASS] DE OFF");

        end else begin

            $display("[FAIL] DE OFF");
        end

        $finish;
    end





endmodule
