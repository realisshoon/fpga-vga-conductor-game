`timescale 1ns / 1ps

module xy_detection(
    input  logic        clk,
    input  logic        rst,
    input  logic        i_red_detect,
    input  logic        i_green_detect,
    input  logic [9:0]  i_x_detect_pixel,
    input  logic [9:0]  i_y_detect_pixel,
    input  logic        xy_control_ready,

    output logic [9:0]  o_stick_x_pixel,
    output logic [9:0]  o_stick_y_pixel,
    output logic [9:0]  o_hand_x_pixel,
    output logic [9:0]  o_hand_y_pixel,
    output logic        o_vsync,
    output logic [39:0] o_pixel,
    output logic        xy_control_valid
);

    logic [9:0] stick_x_min, stick_x_max;
    logic [9:0] stick_y_min, stick_y_max;
    logic [9:0] hand_x_min, hand_x_max;
    logic [9:0] hand_y_min, hand_y_max;

    logic red_found;
    logic green_found;

    logic frame_done;
    logic frame_done_d;
    logic frame_done_pulse;

    logic valid_delay;

    logic [9:0] stick_x_center;
    logic [9:0] stick_y_center;
    logic [9:0] hand_x_center;
    logic [9:0] hand_y_center;

    assign frame_done =
        (i_x_detect_pixel == 10'd320) &&
        (i_y_detect_pixel == 10'd239);

    assign frame_done_pulse =
        frame_done && !frame_done_d;

    assign stick_x_center =
        stick_x_min + ((stick_x_max - stick_x_min) >> 1);

    assign stick_y_center =
        stick_y_min + ((stick_y_max - stick_y_min) >> 1);

    assign hand_x_center =
        hand_x_min + ((hand_x_max - hand_x_min) >> 1);

    assign hand_y_center =
        hand_y_min + ((hand_y_max - hand_y_min) >> 1);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_stick_x_pixel <= 10'd1023;
            o_stick_y_pixel <= 10'd1023;
            o_hand_x_pixel  <= 10'd1023;
            o_hand_y_pixel  <= 10'd1023;

            o_vsync          <= 1'b0;
            o_pixel          <= {10'd1023, 10'd1023, 10'd1023, 10'd1023};
            xy_control_valid <= 1'b0;

            stick_x_min <= 10'd1023;
            stick_x_max <= 10'd0;
            stick_y_min <= 10'd1023;
            stick_y_max <= 10'd0;

            hand_x_min <= 10'd1023;
            hand_x_max <= 10'd0;
            hand_y_min <= 10'd1023;
            hand_y_max <= 10'd0;

            red_found   <= 1'b0;
            green_found <= 1'b0;

            frame_done_d <= 1'b0;
            valid_delay  <= 1'b0;

        end else begin
            o_vsync      <= 1'b0;
            frame_done_d <= frame_done;

            if (frame_done_pulse) begin
                o_vsync          <= 1'b1;
                xy_control_valid <= 1'b0;

                if (red_found || green_found) begin
                    valid_delay <= 1'b1;
                end else begin
                    valid_delay <= 1'b0;
                end

            end else if (valid_delay) begin
                xy_control_valid <= 1'b1;
                valid_delay      <= 1'b0;

            end else if (xy_control_valid && xy_control_ready) begin
                xy_control_valid <= 1'b0;
            end

            if (frame_done_pulse) begin
                if (red_found) begin
                    o_stick_x_pixel <= stick_x_center;
                    o_stick_y_pixel <= stick_y_center;
                end else begin
                    o_stick_x_pixel <= 10'd1023;
                    o_stick_y_pixel <= 10'd1023;
                end

                if (green_found) begin
                    o_hand_x_pixel <= hand_x_center;
                    o_hand_y_pixel <= hand_y_center;
                end else begin
                    o_hand_x_pixel <= 10'd1023;
                    o_hand_y_pixel <= 10'd1023;
                end

                o_pixel <= {
                    red_found   ? stick_x_center : 10'd1023,
                    red_found   ? stick_y_center : 10'd1023,
                    green_found ? hand_x_center  : 10'd1023,
                    green_found ? hand_y_center  : 10'd1023
                };

                stick_x_min <= 10'd1023;
                stick_x_max <= 10'd0;
                stick_y_min <= 10'd1023;
                stick_y_max <= 10'd0;

                hand_x_min <= 10'd1023;
                hand_x_max <= 10'd0;
                hand_y_min <= 10'd1023;
                hand_y_max <= 10'd0;

                red_found   <= 1'b0;
                green_found <= 1'b0;

            end else begin
                if (i_red_detect) begin
                    red_found <= 1'b1;

                    if (i_x_detect_pixel <= stick_x_min) begin
                        stick_x_min <= i_x_detect_pixel;
                    end

                    if (i_x_detect_pixel >= stick_x_max) begin
                        stick_x_max <= i_x_detect_pixel;
                    end

                    if (i_y_detect_pixel <= stick_y_min) begin
                        stick_y_min <= i_y_detect_pixel;
                    end

                    if (i_y_detect_pixel >= stick_y_max) begin
                        stick_y_max <= i_y_detect_pixel;
                    end
                end

                if (i_green_detect) begin
                    green_found <= 1'b1;

                    if (i_x_detect_pixel <= hand_x_min) begin
                        hand_x_min <= i_x_detect_pixel;
                    end

                    if (i_x_detect_pixel >= hand_x_max) begin
                        hand_x_max <= i_x_detect_pixel;
                    end

                    if (i_y_detect_pixel <= hand_y_min) begin
                        hand_y_min <= i_y_detect_pixel;
                    end

                    if (i_y_detect_pixel >= hand_y_max) begin
                        hand_y_max <= i_y_detect_pixel;
                    end
                end
            end
        end
    end

endmodule