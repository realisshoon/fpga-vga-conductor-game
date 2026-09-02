`timescale 1ns / 1ps

module tb_xy_detection;

    localparam MODE_NONE  = 2'd0;
    localparam MODE_RED   = 2'd1;
    localparam MODE_GREEN = 2'd2;
    localparam MODE_BOTH  = 2'd3;

    logic        clk;
    logic        rst;

    logic        i_red_detect;
    logic        i_green_detect;
    logic [9:0]  i_x_detect_pixel;
    logic [9:0]  i_y_detect_pixel;

    logic        xy_control_ready;

    logic [9:0]  o_stick_x_pixel;
    logic [9:0]  o_stick_y_pixel;
    logic [9:0]  o_hand_x_pixel;
    logic [9:0]  o_hand_y_pixel;

    logic        o_vsync;
    logic [39:0] o_pixel;
    logic        xy_control_valid;

    logic [9:0]  tb_x_view;
    logic [9:0]  tb_y_view;
    logic        tb_de;

    logic [3:0]  tb_frame_num;
    logic [1:0]  tb_mode;

    logic [9:0]  tb_stick_x_view;
    logic [9:0]  tb_stick_y_view;
    logic [9:0]  tb_hand_x_view;
    logic [9:0]  tb_hand_y_view;

    logic [9:0]  tb_pixel_stick_x_view;
    logic [9:0]  tb_pixel_stick_y_view;
    logic [9:0]  tb_pixel_hand_x_view;
    logic [9:0]  tb_pixel_hand_y_view;

    logic        tb_frame_done;
    logic        tb_frame_done_d;
    logic        tb_frame_done_pulse;
    logic        tb_valid_delay;

    logic [39:0] held_pixel;

    integer error_count;
    integer handshake_count;
    integer frame_done_count;


    xy_detection DUT (
        .clk               (clk),
        .rst               (rst),

        .i_red_detect      (i_red_detect),
        .i_green_detect    (i_green_detect),

        .i_x_detect_pixel  (i_x_detect_pixel),
        .i_y_detect_pixel  (i_y_detect_pixel),

        .xy_control_ready  (xy_control_ready),

        .o_stick_x_pixel   (o_stick_x_pixel),
        .o_stick_y_pixel   (o_stick_y_pixel),

        .o_hand_x_pixel    (o_hand_x_pixel),
        .o_hand_y_pixel    (o_hand_y_pixel),

        .o_vsync           (o_vsync),
        .o_pixel           (o_pixel),

        .xy_control_valid  (xy_control_valid)
    );


    always #5 clk = ~clk;


    assign tb_de =
        (tb_x_view <= 10'd15) &&
        (tb_y_view <= 10'd15);


    assign tb_frame_done       = DUT.frame_done;
    assign tb_frame_done_d     = DUT.frame_done_d;
    assign tb_frame_done_pulse = DUT.frame_done_pulse;
    assign tb_valid_delay      = DUT.valid_delay;


    function automatic [9:0] map_x(
        input integer x
    );
        begin
            case (x)
                16: map_x = 10'd320;
                17: map_x = 10'd480;
                18: map_x = 10'd640;
                19: map_x = 10'd799;

                default:
                    map_x = ((x * 319) + 7) / 15;
            endcase
        end
    endfunction


    function automatic [9:0] map_y(
        input integer y
    );
        begin
            case (y)
                16: map_y = 10'd240;
                17: map_y = 10'd320;
                18: map_y = 10'd480;
                19: map_y = 10'd524;

                default:
                    map_y = ((y * 239) + 7) / 15;
            endcase
        end
    endfunction


    function automatic [9:0] view_x(
        input logic [9:0] x
    );
        begin
            if (x == 10'd1023) begin
                view_x = 10'd19;
            end else if (x <= 10'd319) begin
                view_x = ((x * 15) + 159) / 319;
            end else begin
                view_x = 10'd19;
            end
        end
    endfunction


    function automatic [9:0] view_y(
        input logic [9:0] y
    );
        begin
            if (y == 10'd1023) begin
                view_y = 10'd19;
            end else if (y <= 10'd239) begin
                view_y = ((y * 15) + 119) / 239;
            end else begin
                view_y = 10'd19;
            end
        end
    endfunction


    assign tb_stick_x_view = view_x(o_stick_x_pixel);
    assign tb_stick_y_view = view_y(o_stick_y_pixel);

    assign tb_hand_x_view = view_x(o_hand_x_pixel);
    assign tb_hand_y_view = view_y(o_hand_y_pixel);


    assign tb_pixel_stick_x_view = view_x(o_pixel[39:30]);
    assign tb_pixel_stick_y_view = view_y(o_pixel[29:20]);

    assign tb_pixel_hand_x_view = view_x(o_pixel[19:10]);
    assign tb_pixel_hand_y_view = view_y(o_pixel[9:0]);


    task automatic drive_pixel(
        input integer x,
        input integer y,
        input logic [1:0] mode
    );

        integer k;

        begin
            @(negedge clk);

            tb_x_view = x;
            tb_y_view = y;

            i_x_detect_pixel = map_x(x);
            i_y_detect_pixel = map_y(y);

            i_red_detect   = 1'b0;
            i_green_detect = 1'b0;

            if ((x <= 15) && (y <= 15)) begin

                if ((mode == MODE_RED) ||
                    (mode == MODE_BOTH)) begin

                    if ((x >= 2) && (x <= 4) &&
                        (y >= 3) && (y <= 5)) begin

                        i_red_detect = 1'b1;
                    end
                end

                if ((mode == MODE_GREEN) ||
                    (mode == MODE_BOTH)) begin

                    if ((x >= 10) && (x <= 12) &&
                        (y >= 6)  && (y <= 8)) begin

                        i_green_detect = 1'b1;
                    end
                end
            end

            for (k = 0; k < 4; k = k + 1) begin
                @(posedge clk);
                #1;
            end
        end

    endtask


    task automatic scan_frame(
        input logic [1:0] mode
    );

        integer x;
        integer y;

        begin
            tb_mode = mode;

            for (y = 0; y < 20; y = y + 1) begin
                for (x = 0; x < 20; x = x + 1) begin

                    drive_pixel(
                        x,
                        y,
                        mode
                    );

                end
            end

            tb_frame_num = tb_frame_num + 1;
        end

    endtask


    task automatic check_frame_result;

        logic [9:0] expected_stick_x;
        logic [9:0] expected_stick_y;
        logic [9:0] expected_hand_x;
        logic [9:0] expected_hand_y;

        begin

            case (tb_mode)

                MODE_RED: begin
                    expected_stick_x = 10'd3;
                    expected_stick_y = 10'd4;
                    expected_hand_x  = 10'd19;
                    expected_hand_y  = 10'd19;
                end

                MODE_GREEN: begin
                    expected_stick_x = 10'd19;
                    expected_stick_y = 10'd19;
                    expected_hand_x  = 10'd11;
                    expected_hand_y  = 10'd7;
                end

                MODE_BOTH: begin
                    expected_stick_x = 10'd3;
                    expected_stick_y = 10'd4;
                    expected_hand_x  = 10'd11;
                    expected_hand_y  = 10'd7;
                end

                default: begin
                    expected_stick_x = 10'd19;
                    expected_stick_y = 10'd19;
                    expected_hand_x  = 10'd19;
                    expected_hand_y  = 10'd19;
                end

            endcase


            if ((tb_stick_x_view !== expected_stick_x) ||
                (tb_stick_y_view !== expected_stick_y) ||
                (tb_hand_x_view  !== expected_hand_x)  ||
                (tb_hand_y_view  !== expected_hand_y)) begin

                $display(
                    "ERROR FRAME %0d | STICK=(%0d,%0d) HAND=(%0d,%0d)",
                    tb_frame_num,
                    tb_stick_x_view,
                    tb_stick_y_view,
                    tb_hand_x_view,
                    tb_hand_y_view
                );

                error_count = error_count + 1;

            end else begin

                $display(
                    "FRAME %0d PASS | STICK=(%0d,%0d) HAND=(%0d,%0d)",
                    tb_frame_num,
                    tb_stick_x_view,
                    tb_stick_y_view,
                    tb_hand_x_view,
                    tb_hand_y_view
                );

            end


            if ((tb_pixel_stick_x_view !== expected_stick_x) ||
                (tb_pixel_stick_y_view !== expected_stick_y) ||
                (tb_pixel_hand_x_view  !== expected_hand_x)  ||
                (tb_pixel_hand_y_view  !== expected_hand_y)) begin

                $display(
                    "ERROR FRAME %0d | O_PIXEL DATA MISMATCH",
                    tb_frame_num
                );

                error_count = error_count + 1;
            end


            if (o_vsync !== 1'b1) begin

                $display(
                    "ERROR FRAME %0d | O_VSYNC NOT HIGH AT FRAME_DONE",
                    tb_frame_num
                );

                error_count = error_count + 1;
            end


            if (xy_control_valid !== 1'b0) begin

                $display(
                    "ERROR FRAME %0d | VALID MUST BE 0 AT FRAME_DONE",
                    tb_frame_num
                );

                error_count = error_count + 1;
            end

        end

    endtask


    always @(posedge clk) begin

        if (!rst && DUT.frame_done_pulse) begin

            #1;

            frame_done_count = frame_done_count + 1;

            check_frame_result();

        end

    end


    always @(posedge clk) begin

        if (!rst &&
            xy_control_valid &&
            xy_control_ready) begin

            handshake_count = handshake_count + 1;

            $display(
                "UART HANDSHAKE | FRAME=%0d | DATA=%h",
                tb_frame_num,
                o_pixel
            );

        end

    end


    initial begin

        clk = 1'b0;
        rst = 1'b1;

        i_red_detect   = 1'b0;
        i_green_detect = 1'b0;

        i_x_detect_pixel = 10'd799;
        i_y_detect_pixel = 10'd524;

        xy_control_ready = 1'b1;

        tb_x_view = 10'd19;
        tb_y_view = 10'd19;

        tb_frame_num = 4'd1;
        tb_mode      = MODE_NONE;

        error_count      = 0;
        handshake_count  = 0;
        frame_done_count = 0;

        held_pixel = 40'd0;


        repeat (4)
            @(posedge clk);


        @(negedge clk);

        rst = 1'b0;


        $display("");
        $display("FRAME 1 : RED / READY=1");

        scan_frame(MODE_RED);


        $display("");
        $display("FRAME 2 : GREEN / READY=1");

        scan_frame(MODE_GREEN);


        $display("");
        $display("FRAME 3 : BOTH / READY=1");

        scan_frame(MODE_BOTH);


        $display("");
        $display("FRAME 4 : NONE / READY=1");

        scan_frame(MODE_NONE);


        xy_control_ready = 1'b0;


        $display("");
        $display("FRAME 5 : RED / READY=0");

        scan_frame(MODE_RED);


        $display("");
        $display("FRAME 6 : GREEN / READY=0");

        scan_frame(MODE_GREEN);


        $display("");
        $display("FRAME 7 : NONE / READY=0");

        scan_frame(MODE_NONE);


        $display("");
        $display("FRAME 8 : RED / READY=0");

        scan_frame(MODE_RED);


        held_pixel = o_pixel;


        $display("");
        $display("==============================");
        $display(" VALID HOLD TEST");
        $display("==============================");


        if (xy_control_valid !== 1'b1) begin

            $display("ERROR : VALID SHOULD BE HIGH WHILE READY=0");

            error_count = error_count + 1;

        end else begin

            $display("PASS : VALID IS HIGH WHILE READY=0");

        end


        repeat (6) begin

            @(posedge clk);
            #1;

            if (xy_control_valid !== 1'b1) begin

                $display("ERROR : VALID DROPPED BEFORE READY");

                error_count = error_count + 1;
            end


            if (o_pixel !== held_pixel) begin

                $display("ERROR : O_PIXEL CHANGED WHILE WAITING READY");

                error_count = error_count + 1;
            end

        end


        $display("");
        $display("READY ASSERTED");


        @(negedge clk);

        xy_control_ready = 1'b1;


        @(posedge clk);
        #1;


        if (xy_control_valid !== 1'b0) begin

            $display("ERROR : VALID DID NOT CLEAR AFTER HANDSHAKE");

            error_count = error_count + 1;

        end else begin

            $display("PASS : VALID CLEARED AFTER READY/VALID HANDSHAKE");

        end


        if (o_pixel !== held_pixel) begin

            $display("ERROR : O_PIXEL CHANGED DURING HANDSHAKE");

            error_count = error_count + 1;
        end


        $display("");
        $display("==============================");
        $display(" SIMULATION RESULT");
        $display("==============================");

        $display(
            "FRAME_DONE COUNT = %0d",
            frame_done_count
        );

        $display(
            "UART HANDSHAKE COUNT = %0d",
            handshake_count
        );


        if (frame_done_count !== 8) begin

            $display("ERROR : FRAME_DONE COUNT SHOULD BE 8");

            error_count = error_count + 1;
        end


        if (handshake_count !== 4) begin

            $display("ERROR : HANDSHAKE COUNT SHOULD BE 4");

            error_count = error_count + 1;
        end


        if (error_count == 0) begin

            $display("");
            $display("==============================");
            $display("       ALL TESTS PASS");
            $display("==============================");

        end else begin

            $display("");
            $display("==============================");
            $display("       TEST FAILED");
            $display("       ERROR = %0d", error_count);
            $display("==============================");

        end


        #100;

        $finish;

    end

endmodule