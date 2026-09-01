`timescale 1ns / 1ps

module rgb_filter #(
    // Red detection parameters
    parameter logic [3:0] RED_MIN      = 4'd8,
    parameter logic [3:0] RED_G_MARGIN = 4'd3,
    parameter logic [3:0] RED_B_MARGIN = 4'd3,

    // Green detection parameters
    parameter logic [3:0] GREEN_MIN      = 4'd7,
    parameter logic [3:0] GREEN_R_MARGIN = 4'd2,
    parameter logic [3:0] GREEN_B_MARGIN = 4'd2
) (
    input  logic        clk,
    input  logic        rst,
    // RGB444 pixel input
    input  logic [11:0] i_rgb,
    input  logic [ 9:0] i_x_pixel,
    input  logic [ 9:0] i_y_pixel,
    input  logic        de,
    //output
    output logic        o_red_detect,
    output logic        o_green_detect,
    output logic [ 9:0] o_x_detect_pixel,
    output logic [ 9:0] o_y_detect_pixel
);

    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;

    assign red   = i_rgb[11:8];
    assign green = i_rgb[7:4];
    assign blue  = i_rgb[3:0];

    logic red_detect;
    logic green_detect;

    always_comb begin
        red_detect   = 1'b0;
        green_detect = 1'b0;

        if (de) begin

            // Red detection
            if ((red >= RED_MIN) &&
            (red >= green) &&
            ((red - green) >= RED_G_MARGIN) &&
            (red >= blue) &&
            ((red - blue) >= RED_B_MARGIN)) begin

                red_detect = 1'b1;
            end

            // Green detection
            if ((green >= GREEN_MIN) &&
            (green >= red) &&
            ((green - red) >= GREEN_R_MARGIN) &&
            (green >= blue) &&
            ((green - blue) >= GREEN_B_MARGIN)) begin

                green_detect = 1'b1;
            end
        end
    end


    always_ff @(posedge clk) begin
        if (rst) begin
            o_red_detect     <= 1'b0;
            o_green_detect   <= 1'b0;

            o_x_detect_pixel <= 10'd0;
            o_y_detect_pixel <= 10'd0;
        end else begin
            o_red_detect     <= red_detect;
            o_green_detect   <= green_detect;

            o_x_detect_pixel <= i_x_pixel;
            o_y_detect_pixel <= i_y_pixel;
        end
    end

endmodule
