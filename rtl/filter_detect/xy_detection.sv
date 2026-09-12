`timescale 1ns / 1ps

module xy_detection #(
    parameter int unsigned RED_MIN_CLUSTER_PIXELS   = 8,
    parameter int unsigned GREEN_MIN_CLUSTER_PIXELS = 16,

    parameter logic [9:0] RED_CLUSTER_MARGIN   = 10'd24,
    parameter logic [9:0] GREEN_CLUSTER_MARGIN = 10'd24
) (
    input logic       clk,
    input logic       rst,
    input logic       i_red_detect,
    input logic       i_green_detect,
    input logic [9:0] i_x_detect_pixel,
    input logic [9:0] i_y_detect_pixel,
    input logic       xy_control_ready,

    output logic [ 9:0] o_stick_x_pixel,
    output logic [ 9:0] o_stick_y_pixel,
    output logic [ 9:0] o_hand_x_pixel,
    output logic [ 9:0] o_hand_y_pixel,
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


    logic [16:0] red_cluster_count;
    logic [16:0] green_cluster_count;


    logic frame_done;
    logic frame_done_d;
    logic frame_done_pulse;


    logic valid_delay;


    logic [9:0] stick_x_center;
    logic [9:0] stick_y_center;

    logic [9:0] hand_x_center;
    logic [9:0] hand_y_center;


    // 이전 Line의 색상 검출 결과 저장
    logic [319:0] red_linebuf;
    logic [319:0] green_linebuf;


    // 현재 픽셀의 왼쪽 픽셀
    logic red_left_raw;
    logic green_left_raw;


    // 현재 픽셀의 왼쪽 위 픽셀
    logic red_up_left_raw;
    logic green_up_left_raw;


    // 현재 픽셀의 바로 위 픽셀
    logic red_up_raw;
    logic green_up_raw;


    // 주변에 같은 색 픽셀이 존재하는지
    logic red_neighbor;
    logic green_neighbor;


    // 실제 군체 후보 픽셀
    logic red_group_pixel;
    logic green_group_pixel;


    // 현재 Bounding Box 주변에 있는 픽셀인지
    logic red_near_cluster;
    logic green_near_cluster;


    // 동일한 VGA 좌표가 여러 system clk 유지되는 경우
    // 한 픽셀당 한 번만 처리하기 위한 신호
    logic [9:0] prev_x_pixel;
    logic [9:0] prev_y_pixel;

    logic pixel_tick;


    // 실제 QVGA 검출 영역
    logic active_qvga;



    //==================================================
    // QVGA ACTIVE AREA
    //==================================================

    assign active_qvga = (i_x_detect_pixel < 10'd320) && (i_y_detect_pixel < 10'd240);



    //==================================================
    // PIXEL TICK
    //==================================================

    assign pixel_tick = (i_x_detect_pixel != prev_x_pixel) || (i_y_detect_pixel != prev_y_pixel);



    //==================================================
    // INTERNAL FRAME DONE
    //==================================================

    assign frame_done = (i_x_detect_pixel == 10'd320) && (i_y_detect_pixel == 10'd239);


    assign frame_done_pulse = frame_done && !frame_done_d;



    //==================================================
    // CENTER CALCULATION
    //==================================================

    assign stick_x_center = stick_x_min + ((stick_x_max - stick_x_min) >> 1);


    assign stick_y_center = stick_y_min + ((stick_y_max - stick_y_min) >> 1);


    assign hand_x_center = hand_x_min + ((hand_x_max - hand_x_min) >> 1);


    assign hand_y_center = hand_y_min + ((hand_y_max - hand_y_min) >> 1);



    //==================================================
    // PREVIOUS LINE PIXEL
    //==================================================

    always_comb begin

        red_up_raw   = 1'b0;
        green_up_raw = 1'b0;

        if (i_x_detect_pixel < 10'd320) begin

            red_up_raw   = red_linebuf[i_x_detect_pixel];

            green_up_raw = green_linebuf[i_x_detect_pixel];

        end

    end



    //==================================================
    // NEIGHBOR CHECK
    //
    //   UP-LEFT    UP
    //
    //      LEFT    CURRENT
    //
    //==================================================

    assign red_neighbor =

        (
            (i_x_detect_pixel != 10'd0) &&
            red_left_raw
        )

        ||

        red_up_raw

        ||

        (
            (i_x_detect_pixel != 10'd0) &&
            red_up_left_raw
        );


    assign green_neighbor =

        (
            (i_x_detect_pixel != 10'd0) &&
            green_left_raw
        )

        ||

        green_up_raw

        ||

        (
            (i_x_detect_pixel != 10'd0) &&
            green_up_left_raw
        );



    //==================================================
    // GROUP PIXEL
    //
    // 색상이 검출되었더라도 주변에 같은 색 픽셀이
    // 하나라도 존재해야 군체 후보로 인정
    //==================================================

    assign red_group_pixel = active_qvga && pixel_tick && i_red_detect && red_neighbor;


    assign green_group_pixel = active_qvga && pixel_tick && i_green_detect && green_neighbor;



    //==================================================
    // RED CLUSTER RANGE
    //==================================================

    assign red_near_cluster =

        !red_found

        ||

        (
            ((i_x_detect_pixel + RED_CLUSTER_MARGIN)
                >= stick_x_min)

            &&

            (i_x_detect_pixel
                <= (stick_x_max + RED_CLUSTER_MARGIN))

            &&

            ((i_y_detect_pixel + RED_CLUSTER_MARGIN)
                >= stick_y_min)

            &&

            (i_y_detect_pixel
                <= (stick_y_max + RED_CLUSTER_MARGIN))
        );



    //==================================================
    // GREEN CLUSTER RANGE
    //==================================================

    assign green_near_cluster =

        !green_found

        ||

        (
            ((i_x_detect_pixel + GREEN_CLUSTER_MARGIN)
                >= hand_x_min)

            &&

            (i_x_detect_pixel
                <= (hand_x_max + GREEN_CLUSTER_MARGIN))

            &&

            ((i_y_detect_pixel + GREEN_CLUSTER_MARGIN)
                >= hand_y_min)

            &&

            (i_y_detect_pixel
                <= (hand_y_max + GREEN_CLUSTER_MARGIN))
        );



    //==================================================
    // MAIN SEQUENTIAL LOGIC
    //==================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            o_stick_x_pixel <= 10'd1023;
            o_stick_y_pixel <= 10'd1023;

            o_hand_x_pixel <= 10'd1023;
            o_hand_y_pixel <= 10'd1023;


            o_vsync <= 1'b0;


            o_pixel <= {10'd1023, 10'd1023, 10'd1023, 10'd1023};


            xy_control_valid <= 1'b0;


            // RED Bounding Box

            stick_x_min <= 10'd1023;
            stick_x_max <= 10'd0;

            stick_y_min <= 10'd1023;
            stick_y_max <= 10'd0;


            // GREEN Bounding Box

            hand_x_min <= 10'd1023;
            hand_x_max <= 10'd0;

            hand_y_min <= 10'd1023;
            hand_y_max <= 10'd0;


            // FOUND

            red_found <= 1'b0;
            green_found <= 1'b0;


            // CLUSTER COUNT

            red_cluster_count <= 17'd0;
            green_cluster_count <= 17'd0;


            // LINE BUFFER

            red_linebuf <= '0;
            green_linebuf <= '0;


            red_left_raw <= 1'b0;
            green_left_raw <= 1'b0;


            red_up_left_raw <= 1'b0;
            green_up_left_raw <= 1'b0;


            // FRAME

            frame_done_d <= 1'b0;


            // READY / VALID

            valid_delay <= 1'b0;


            // PIXEL TICK

            prev_x_pixel <= 10'd1023;
            prev_y_pixel <= 10'd1023;

        end else begin


            // 기본값
            o_vsync <= 1'b0;


            // frame_done 이전값 저장
            frame_done_d <= frame_done;


            // 이전 좌표 저장
            prev_x_pixel <= i_x_detect_pixel;
            prev_y_pixel <= i_y_detect_pixel;



            //==================================================
            // READY / VALID CONTROL
            //==================================================

            if (frame_done_pulse) begin

                o_vsync <= 1'b1;


                // 이전 Frame의 valid가 남아 있어도
                // 새로운 Frame 결과 시점에서 제거
                xy_control_valid <= 1'b0;


                if (red_found || green_found) begin

                    valid_delay <= 1'b1;

                end else begin

                    valid_delay <= 1'b0;

                end


            end else if (valid_delay) begin


                xy_control_valid <= 1'b1;

                valid_delay <= 1'b0;


            end else if (xy_control_valid && xy_control_ready) begin


                xy_control_valid <= 1'b0;

            end



            //==================================================
            // FRAME RESULT
            //==================================================

            if (frame_done_pulse) begin


                //==================================================
                // RED RESULT
                //==================================================

                if (red_found) begin

                    o_stick_x_pixel <= stick_x_center;

                    o_stick_y_pixel <= stick_y_center;

                end else begin

                    o_stick_x_pixel <= 10'd1023;

                    o_stick_y_pixel <= 10'd1023;

                end



                //==================================================
                // GREEN RESULT
                //==================================================

                if (green_found) begin

                    o_hand_x_pixel <= hand_x_center;

                    o_hand_y_pixel <= hand_y_center;

                end else begin

                    o_hand_x_pixel <= 10'd1023;

                    o_hand_y_pixel <= 10'd1023;

                end



                //==================================================
                // UART DATA
                //==================================================

                o_pixel <= {

                    red_found ? stick_x_center : 10'd1023,

                    red_found ? stick_y_center : 10'd1023,

                    green_found ? hand_x_center : 10'd1023,

                    green_found ? hand_y_center : 10'd1023

                };



                //==================================================
                // RESET FOR NEXT FRAME
                //==================================================

                stick_x_min <= 10'd1023;
                stick_x_max <= 10'd0;

                stick_y_min <= 10'd1023;
                stick_y_max <= 10'd0;


                hand_x_min <= 10'd1023;
                hand_x_max <= 10'd0;

                hand_y_min <= 10'd1023;
                hand_y_max <= 10'd0;


                red_cluster_count <= 17'd0;
                green_cluster_count <= 17'd0;


                red_found <= 1'b0;
                green_found <= 1'b0;


                red_linebuf <= '0;
                green_linebuf <= '0;


                red_left_raw <= 1'b0;
                green_left_raw <= 1'b0;


                red_up_left_raw <= 1'b0;
                green_up_left_raw <= 1'b0;



            end else if (active_qvga && pixel_tick) begin



                //==================================================
                // LINE BUFFER UPDATE
                //==================================================

                red_left_raw <= i_red_detect;
                green_left_raw <= i_green_detect;


                red_up_left_raw <= red_up_raw;
                green_up_left_raw <= green_up_raw;


                red_linebuf[i_x_detect_pixel] <= i_red_detect;


                green_linebuf[i_x_detect_pixel] <= i_green_detect;



                //==================================================
                // RED CLUSTER
                //==================================================

                if (red_group_pixel && red_near_cluster) begin


                    red_cluster_count <= red_cluster_count + 1'b1;


                    /*
                     * 현재 Pixel까지 포함했을 때
                     * RED_MIN_CLUSTER_PIXELS 이상이면
                     * 실제 RED 군체로 인정
                     */

                    if (red_cluster_count >= (RED_MIN_CLUSTER_PIXELS - 1)) begin

                        red_found <= 1'b1;

                    end



                    // RED Bounding Box

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



                //==================================================
                // GREEN CLUSTER
                //==================================================

                if (green_group_pixel && green_near_cluster) begin


                    green_cluster_count <= green_cluster_count + 1'b1;


                    /*
                     * 현재 Pixel까지 포함했을 때
                     * GREEN_MIN_CLUSTER_PIXELS 이상이면
                     * 실제 GREEN 군체로 인정
                     */

                    if (green_cluster_count >= (GREEN_MIN_CLUSTER_PIXELS - 1)) begin

                        green_found <= 1'b1;

                    end



                    // GREEN Bounding Box

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
