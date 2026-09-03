`timescale 1ns / 1ps

module rgb_filter #(
    // Red detection parameters
    parameter logic [3:0] RED_MIN      = 4'd8,
    parameter logic [3:0] RED_G_MARGIN = 4'd3,
    parameter logic [3:0] RED_B_MARGIN = 4'd3,

    // Green detection parameters
    parameter logic [3:0] GREEN_MIN      = 4'd9,
    parameter logic [3:0] GREEN_R_MARGIN = 4'd4,
    parameter logic [3:0] GREEN_B_MARGIN = 4'd4,

    // Blue detection parameters
    parameter logic [3:0] BLUE_MIN      = 4'd9,
    parameter logic [3:0] BLUE_R_MARGIN = 4'd4,
    parameter logic [3:0] BLUE_G_MARGIN = 4'd4
) (
    input logic clk,
    input logic rst,

    // Existing rgb_filter interface - keep as-is
    input logic [11:0] i_rgb,
    input logic [ 9:0] i_x_pixel,
    input logic [ 9:0] i_y_pixel,
    input logic        de,

    output logic       o_red_detect,
    output logic       o_green_detect,
    output logic [9:0] o_x_detect_pixel,
    output logic [9:0] o_y_detect_pixel,

    // VGA filter control / path
    input logic SW_RED,
    input logic SW_GREEN,
    input logic SW_BLUE,

    input logic H_SYNC_IN,
    input logic V_SYNC_IN,

    output logic        H_SYNC,
    output logic        V_SYNC,
    output logic [11:0] RGB
);

    localparam logic [11:0] C_RED   = 12'hF00;
    localparam logic [11:0] C_GREEN = 12'h0F0;
    localparam logic [11:0] C_BLUE  = 12'h00F;
    localparam logic [11:0] C_BLACK = 12'h000;

    // Internal signals stay lowercase
    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;

    logic red_detect;
    logic green_detect;
    logic blue_detect;

    logic [11:0] filter_rgb;

    assign red   = i_rgb[11:8];
    assign green = i_rgb[7:4];
    assign blue  = i_rgb[3:0];


    // =========================================================
    // Color Detection
    // =========================================================
    always_comb begin
        red_detect   = 1'b0;
        green_detect = 1'b0;
        blue_detect  = 1'b0;

        if (de) begin

            // -------------------------------------------------
            // Red detection
            // R must be sufficiently large and
            // sufficiently greater than G/B.
            // -------------------------------------------------
            if ((red >= RED_MIN) &&
                (red >= green) &&
                ((red - green) >= RED_G_MARGIN) &&
                (red >= blue) &&
                ((red - blue) >= RED_B_MARGIN)) begin

                red_detect = 1'b1;
            end


            // -------------------------------------------------
            // Green detection
            // G must be sufficiently large and
            // sufficiently greater than R/B.
            // -------------------------------------------------
            if ((green >= GREEN_MIN) &&
                (green >= red) &&
                ((green - red) >= GREEN_R_MARGIN) &&
                (green >= blue) &&
                ((green - blue) >= GREEN_B_MARGIN)) begin

                green_detect = 1'b1;
            end


            // -------------------------------------------------
            // Blue detection
            // B must be sufficiently large and
            // sufficiently greater than R/G.
            // -------------------------------------------------
            if ((blue >= BLUE_MIN) &&
                (blue >= red) &&
                ((blue - red) >= BLUE_R_MARGIN) &&
                (blue >= green) &&
                ((blue - green) >= BLUE_G_MARGIN)) begin

                blue_detect = 1'b1;
            end
        end
    end


    // =========================================================
    // VGA Debug Filter
    //
    // SW_RED   = Red detection visualization
    // SW_GREEN = Green detection visualization
    // SW_BLUE  = Blue detection visualization
    //
    // all OFF  = Original RGB
    //
    // More than one switch can be enabled simultaneously.
    // =========================================================
    always_comb begin
        filter_rgb = C_BLACK;

        if (de) begin

            // All filters OFF -> original image
            if (!SW_RED && !SW_GREEN && !SW_BLUE) begin
                filter_rgb = i_rgb;
            end  // Filter mode
            else begin
                if (SW_RED && red_detect) begin
                    filter_rgb = C_RED;
                end else if (SW_GREEN && green_detect) begin
                    filter_rgb = C_GREEN;
                end else if (SW_BLUE && blue_detect) begin
                    filter_rgb = C_BLUE;
                end else begin
                    filter_rgb = C_BLACK;
                end
            end
        end
    end


    // =========================================================
    // Output Register
    //
    // xy_detection path + VGA path are registered together
    // so they remain in the same pixel stage.
    // =========================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            // Existing xy_detection path
            o_red_detect     <= 1'b0;
            o_green_detect   <= 1'b0;
            o_x_detect_pixel <= 10'd0;
            o_y_detect_pixel <= 10'd0;

            // VGA path
            H_SYNC           <= 1'b1;
            V_SYNC           <= 1'b1;
            RGB              <= C_BLACK;

        end else begin
            // Existing xy_detection path
            o_red_detect     <= red_detect;
            o_green_detect   <= green_detect;
            o_x_detect_pixel <= i_x_pixel;
            o_y_detect_pixel <= i_y_pixel;

            // VGA path - same pixel stage
            H_SYNC           <= H_SYNC_IN;
            V_SYNC           <= V_SYNC_IN;
            RGB              <= filter_rgb;
        end
    end

endmodule
