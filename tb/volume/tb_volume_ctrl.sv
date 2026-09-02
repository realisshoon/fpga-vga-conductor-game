`timescale 1ns / 1ps

module tb_volume_ctrl;

    // DUT 입력 신호
    logic       clk;
    logic       rst;
    logic       i_vsync;
    logic [9:0] i_hand_y_pixel;
    logic       volume_control_ready;

    // DUT 출력 신호
    logic       volume_control_valid;
    logic [6:0] o_volume_level;

    localparam logic [9:0] NO_HAND = 10'h0FF;

    // 기능 검증용 100 MHz clock
    // 실제 30 FPS 시간 간격은 기다리지 않고 프레임을 빠르게 발생시킨다.
    localparam time CLK_PERIOD = 10ns;

    // 100 MHz clock: 주기 10 ns
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 검증할 volume_ctrl 인스턴스
    volume_ctrl #(
        .INITIAL_VOLUME (50),
        .MAX_VOLUME     (100),
        .SCALE          (2)
    ) dut (
        .clk                  (clk),
        .rst                  (rst),
        .i_vsync              (i_vsync),
        .i_hand_y_pixel       (i_hand_y_pixel),
        .volume_control_ready (volume_control_ready),
        .volume_control_valid (volume_control_valid),
        .o_volume_level       (o_volume_level)
    );

    // 한 번 호출할 때 한 프레임을 발생시킨다.
    // i_vsync와 y_pixel은 clk 상승 에지 직후에 동시에 변경한다.
    task automatic send_frame(input logic [9:0] y_pixel);
        begin
            // clk 상승 에지 직후 좌표 변경과 VSYNC 상승을 동시에 발생시킨다.
            @(posedge clk);
            #1ps;
            i_hand_y_pixel = y_pixel;
            i_vsync        = 1'b1;

            // 다음 clk 상승 에지에서 DUT가 좌표를 처리한 뒤 VSYNC를 내린다.
            @(posedge clk);
            #1ps;
            i_vsync = 1'b0;
        end
    endtask

    // 현재 출력과 예상 출력을 비교한다.
    task automatic check_output(
        input logic [6:0] expected_volume,
        input logic       expected_valid
    );
        begin
            if ((o_volume_level !== expected_volume) ||
                (volume_control_valid !== expected_valid)) begin
                $display("[FAIL] time=%0t, volume=%0d(expected %0d), valid=%0b(expected %0b)",
                         $time, o_volume_level, expected_volume,
                         volume_control_valid, expected_valid);
                $fatal(1);
            end else begin
                $display("[PASS] time=%0t, volume=%0d, valid=%0b",
                         $time, o_volume_level, volume_control_valid);
            end
        end
    endtask

    initial begin
        // 초기 입력값
        rst                  = 1'b1;
        i_vsync              = 1'b0;
        i_hand_y_pixel       = NO_HAND;
        volume_control_ready = 1'b1;

        // 비동기 reset을 충분히 인가한 뒤 해제한다.
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        $display("\n[TEST 1] Reset 확인");
        check_output(7'd50, 1'b0);

        // -------------------------------------------------------------
        // TEST 2: WAIT 도중 10번째 프레임에서 손을 놓치면 IDLE 복귀
        // -------------------------------------------------------------
        $display("\n[TEST 2] WAIT 상태의 손 미검출 확인");
        send_frame(10'd180);            // 손 검출: IDLE -> WAIT, count=0
        repeat (9) send_frame(10'd170); // WAIT의 1~9번째 프레임
        send_frame(NO_HAND);            // WAIT의 10번째 프레임: IDLE 복귀

        if (dut.wait_count_c !== 5'd0) begin
            $display("[FAIL] IDLE에서 wait_count가 0으로 초기화되지 않음");
            $fatal(1);
        end
        check_output(7'd50, 1'b0);

        // -------------------------------------------------------------
        // TEST 3: 30번째 프레임 좌표 120을 기준 좌표로 저장
        // 1~29번째 좌표는 기준 좌표로 사용되지 않는다.
        // -------------------------------------------------------------
        $display("\n[TEST 3] 30 Frame 대기와 base_y 저장 확인");
        send_frame(10'd200);            // 손 검출: IDLE -> WAIT, count=0
        repeat (29) send_frame(10'd160); // WAIT의 1~29번째 프레임
        send_frame(10'd120);            // WAIT의 30번째 프레임

        if (dut.wait_count_c !== 5'd0) begin
            $display("[FAIL] TRACK 진입 시 wait_count가 0이 아님");
            $fatal(1);
        end
        if (dut.base_y_c !== 10'd120) begin
            $display("[FAIL] base_y=%0d(expected 120)", dut.base_y_c);
            $fatal(1);
        end
        if (dut.volume_c !== 7'd50) begin
            $display("[FAIL] 초기 volume=%0d(expected 50)", dut.volume_c);
            $fatal(1);
        end
        check_output(7'd50, 1'b0);

        // -------------------------------------------------------------
        // TEST 4: 10프레임 뒤 Y 120 -> 100
        // delta=+20, SCALE=2이므로 volume 50 -> 60
        // 계산 후 base_y도 100으로 갱신된다.
        // -------------------------------------------------------------
        $display("\n[TEST 4] 손을 위로 이동: volume 증가 확인");
        repeat (10) send_frame(10'd100);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.volume_c !== 7'd60) || (dut.base_y_c !== 10'd100)) begin
            $display("[FAIL] volume=%0d(expected 60), base_y=%0d(expected 100)",
                     dut.volume_c, dut.base_y_c);
            $fatal(1);
        end
        check_output(7'd60, 1'b1);

        // ready=1이므로 다음 상승 에지에서 handshake가 완료된다.
        @(posedge clk);
        #1;
        check_output(7'd60, 1'b0);

        // -------------------------------------------------------------
        // TEST 5: 같은 Y=100에 계속 있으면 볼륨이 다시 증가하지 않음
        // -------------------------------------------------------------
        $display("\n[TEST 5] 같은 위치 유지: volume 유지 확인");
        repeat (10) send_frame(10'd100);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.volume_c !== 7'd60) || (dut.base_y_c !== 10'd100)) begin
            $display("[FAIL] 같은 위치에서 volume 또는 base_y가 변경됨");
            $fatal(1);
        end
        check_output(7'd60, 1'b0);

        // -------------------------------------------------------------
        // TEST 6: Y 100 -> 120
        // delta=-20, SCALE=2이므로 volume 60 -> 50
        // -------------------------------------------------------------
        $display("\n[TEST 6] 손을 아래로 이동: volume 감소 확인");
        repeat (10) send_frame(10'd120);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.volume_c !== 7'd50) || (dut.base_y_c !== 10'd120)) begin
            $display("[FAIL] volume=%0d(expected 50), base_y=%0d(expected 120)",
                     dut.volume_c, dut.base_y_c);
            $fatal(1);
        end
        check_output(7'd50, 1'b1);

        @(posedge clk);
        #1;
        check_output(7'd50, 1'b0);

        // -------------------------------------------------------------
        // TEST 7: ready=0이어도 다음 VSYNC에서 valid가 초기화되는지 확인
        // Y 120 -> 80: delta=+40, volume 50 -> 70
        // -------------------------------------------------------------
        $display("\n[TEST 7] ready=0일 때 다음 VSYNC에서 valid 초기화 확인");
        @(negedge clk);
        volume_control_ready = 1'b0;

        repeat (10) send_frame(10'd80);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.volume_c !== 7'd70) || (dut.base_y_c !== 10'd80)) begin
            $display("[FAIL] volume=%0d(expected 70), base_y=%0d(expected 80)",
                     dut.volume_c, dut.base_y_c);
            $fatal(1);
        end
        check_output(7'd70, 1'b1);

        // ready=0인 상태에서 다음 프레임을 발생시킨다.
        // i_vsync에 의해 이전 valid가 0으로 초기화되어야 한다.
        send_frame(10'd80);
        if (dut.track_count_c !== 4'd1) begin
            $display("[FAIL] 다음 VSYNC 후 track_count=%0d(expected 1)",
                     dut.track_count_c);
            $fatal(1);
        end
        check_output(7'd70, 1'b0);

        // ready가 계속 0이어도 valid는 다시 올라오면 안 된다.
        repeat (3) begin
            @(posedge clk);
            #1;
            check_output(7'd70, 1'b0);
        end

        // 이미 valid가 초기화됐으므로 ready를 1로 바꿔도 valid는 0이다.
        @(negedge clk);
        volume_control_ready = 1'b1;
        @(posedge clk);
        #1;
        check_output(7'd70, 1'b0);

        // -------------------------------------------------------------
        // TEST 8: TRACK의 10번째 확인 프레임에서 FF가 들어오면 IDLE
        // -------------------------------------------------------------
        $display("\n[TEST 8] TRACK 상태의 손 미검출 확인");
        // TEST 7의 마지막 VSYNC로 track_count가 이미 1이다.
        repeat (8) send_frame(10'd80);
        send_frame(NO_HAND);

        if ((dut.wait_count_c !== 5'd0) ||
            (dut.track_count_c !== 4'd0)) begin
            $display("[FAIL] IDLE에서 counter가 초기화되지 않음");
            $fatal(1);
        end
        check_output(7'd70, 1'b0);

        // IDLE에서는 FF 입력이 계속 들어와도 아무 변화가 없어야 한다.
        repeat (3) send_frame(NO_HAND);
        check_output(7'd70, 1'b0);

        $display("\n========================================");
        $display(" ALL VOLUME_CTRL TESTS PASSED");
        $display("========================================\n");
        $finish;
    end

endmodule
