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

    localparam logic [9:0] NO_HAND = 10'h3FF;

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

        // -------------------------------------------------------------
        // TEST 1: Reset과 IDLE 초기화
        // -------------------------------------------------------------
        $display("\n[TEST 1] Reset과 IDLE 초기화 확인");
        if ((dut.c_state !== 2'd0)       ||
            (dut.wait_count_c !== 5'd0)  ||
            (dut.track_count_c !== 4'd0) ||
            (dut.base_y_c !== 10'd0)     ||
            (dut.volume_c !== 7'd50)) begin
            $display("[FAIL] Reset 초기값 오류");
            $fatal(1);
        end
        check_output(7'd50, 1'b0);

        // -------------------------------------------------------------
        // TEST 2: WAIT 30번째 프레임에서 base_y 저장 및 TRACK 전환
        // -------------------------------------------------------------
        $display("\n[TEST 2] 30번째 프레임 base_y 저장 및 TRACK 전환");
        send_frame(10'd200);             // 손 검출: IDLE -> WAIT

        if ((dut.c_state !== 2'd1) || (dut.wait_count_c !== 5'd0)) begin
            $display("[FAIL] IDLE에서 WAIT로 전환되지 않음");
            $fatal(1);
        end

        repeat (29) send_frame(10'd160); // WAIT의 1~29번째 프레임
        send_frame(10'd120);             // WAIT의 30번째 프레임

        if ((dut.c_state !== 2'd2)       ||
            (dut.wait_count_c !== 5'd0)  ||
            (dut.track_count_c !== 4'd0) ||
            (dut.base_y_c !== 10'd120)   ||
            (dut.volume_c !== 7'd50)) begin
            $display("[FAIL] TRACK 전환 결과: base_y=%0d, volume=%0d",
                     dut.base_y_c, dut.volume_c);
            $fatal(1);
        end
        check_output(7'd50, 1'b0);

        // -------------------------------------------------------------
        // TEST 3: 손 위 이동으로 volume 50 -> 60
        // base=120, current=100, delta=20, SCALE=2, 변화량=10
        // -------------------------------------------------------------
        $display("\n[TEST 3] 손 위 이동: volume 50 -> 60");
        repeat (10) send_frame(10'd100);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.base_y_c !== 10'd100)   ||
            (dut.volume_c !== 7'd60)) begin
            $display("[FAIL] volume=%0d(expected 60), base_y=%0d(expected 100)",
                     dut.volume_c, dut.base_y_c);
            $fatal(1);
        end
        check_output(7'd60, 1'b1);

        // ready=1이므로 다음 상승 에지에서 valid가 내려간다.
        @(posedge clk);
        #1ps;
        check_output(7'd60, 1'b0);

        // -------------------------------------------------------------
        // TEST 4: 같은 위치에서 volume 60 유지
        // -------------------------------------------------------------
        $display("\n[TEST 4] 같은 위치: volume 60 유지");
        repeat (10) send_frame(10'd100);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.base_y_c !== 10'd100)   ||
            (dut.volume_c !== 7'd60)) begin
            $display("[FAIL] 같은 위치에서 volume 또는 base_y가 변경됨");
            $fatal(1);
        end
        check_output(7'd60, 1'b0);

        // -------------------------------------------------------------
        // TEST 5: ready=0 상태에서 다음 VSYNC로 valid 초기화
        // base=100, current=80이므로 volume 60 -> 70
        // -------------------------------------------------------------
        $display("\n[TEST 5] ready=0에서 다음 VSYNC로 valid 초기화");
        @(negedge clk);
        volume_control_ready = 1'b0;

        repeat (10) send_frame(10'd80);

        if ((dut.track_count_c !== 4'd0) ||
            (dut.base_y_c !== 10'd80)    ||
            (dut.volume_c !== 7'd70)) begin
            $display("[FAIL] volume=%0d(expected 70), base_y=%0d(expected 80)",
                     dut.volume_c, dut.base_y_c);
            $fatal(1);
        end
        check_output(7'd70, 1'b1);

        // ready가 0이어도 다음 VSYNC에서 이전 valid가 0이 되어야 한다.
        send_frame(10'd80);
        if (dut.track_count_c !== 4'd1) begin
            $display("[FAIL] 다음 VSYNC 후 track_count=%0d(expected 1)",
                     dut.track_count_c);
            $fatal(1);
        end
        check_output(7'd70, 1'b0);

        @(negedge clk);
        volume_control_ready = 1'b1;

        // -------------------------------------------------------------
        // TEST 6: NO_HAND(3FF) 입력으로 TRACK -> IDLE 복귀
        // TEST 5에서 track_count=1이므로 8프레임 뒤 count=9가 된다.
        // -------------------------------------------------------------
        $display("\n[TEST 6] 3FF 입력으로 TRACK -> IDLE 복귀");
        repeat (8) send_frame(10'd80);
        send_frame(NO_HAND);

        if ((dut.c_state !== 2'd0)       ||
            (dut.wait_count_c !== 5'd0)  ||
            (dut.track_count_c !== 4'd0) ||
            (dut.volume_c !== 7'd70)) begin
            $display("[FAIL] TRACK에서 IDLE 복귀 결과 오류");
            $fatal(1);
        end
        check_output(7'd70, 1'b0);

        $display("\n========================================");
        $display(" ALL 6 VOLUME_CTRL TESTS PASSED");
        $display("========================================\n");
        $finish;
    end

endmodule
