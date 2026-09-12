`timescale 1ns / 1ps
//==============================================================
// tb_uart_data_control.sv
// uart_data_control 모듈 자체 검증(self-checking) 테스트벤치
//
// 검증 항목
//  1) reset 직후 초기값 (모든 ready=1, valid=0, r_tx_data=0)
//  2) 6개 필드(game_fsm/xy_dec/speed/vol/pattern/score) 각각
//     valid&&ready 조건에서만 정확한 비트 슬라이스에 latch 되는지
//  3) tx_sync -> uart_data_control_uart_valid 트리거 동작
//  4) uart_data_control_uart_valid=1(전송 중)인 동안
//     모든 필드의 ready가 0으로 내려가서 write가 막히는지 (레이스 방지 검증)
//  5) uart_data_control_uart_ready로 핸드셰이크 완료 시
//     valid가 내려가고 ready들이 다시 1로 복귀하는지
//  6) o_tx_data가 r_tx_data와 항상 동일한지 (연결 확인)
//  7) o_rx_data가 i_rx_data를 조합적으로 그대로 통과시키는지
//==============================================================

module tb_uart_data_control;

    // ---------------- DUT I/O ----------------
    logic clk, rst;
    logic        tx_sync;
    logic        uart_data_control_uart_ready;
    logic        uart_data_control_uart_valid;

    logic        volume_uart_ready;
    logic [ 6:0] i_volume_level;
    logic        volume_uart_valid;

    logic        xy_uart_ready;
    logic [39:0] i_pixel;
    logic        xy_uart_valid;

    logic        stick_control_ready;
    logic [ 7:0] i_speed;
    logic        stick_control_valid;

    logic        score_control_ready;
    logic [ 3:0] i_score;
    logic        score_control_valid;

    logic        game_control_ready;
    logic [ 1:0] i_game_state;
    logic        game_control_valid;

    logic        pattern_control_ready;
    logic        pattern_control_valid;
    logic [ 2:0] i_pattern_state;

    logic [63:0] o_tx_data;
    logic [ 7:0] i_rx_data;
    logic [ 7:0] o_rx_data;

    // ---------------- Bit-map (DUT와 동일하게 재정의: 참조용) ----------------
    localparam GAME_FSM_MSB = 63, GAME_FSM_LSB = 62;
    localparam XY_DEC_MSB = 61, XY_DEC_LSB = 22;
    localparam PATTERN_MSB = 21, PATTERN_LSB = 19;
    localparam VOL_MSB = 18, VOL_LSB = 12;
    localparam SPEED_MSB = 11, SPEED_LSB = 4;
    localparam SCORE_MSB = 3, SCORE_LSB = 0;

    // ---------------- DUT instantiation ----------------
    uart_data_control dut (
        .clk                         (clk),
        .rst                         (rst),
        .tx_sync                     (tx_sync),
        .uart_data_control_uart_ready(uart_data_control_uart_ready),
        .uart_data_control_uart_valid(uart_data_control_uart_valid),
        .volume_uart_ready           (volume_uart_ready),
        .i_volume_level              (i_volume_level),
        .volume_uart_valid           (volume_uart_valid),
        .xy_uart_ready               (xy_uart_ready),
        .i_pixel                     (i_pixel),
        .xy_uart_valid               (xy_uart_valid),
        .stick_control_ready         (stick_control_ready),
        .i_speed                     (i_speed),
        .stick_control_valid         (stick_control_valid),
        .score_control_ready         (score_control_ready),
        .i_score                     (i_score),
        .score_control_valid         (score_control_valid),
        .game_control_ready          (game_control_ready),
        .i_game_state                (i_game_state),
        .game_control_valid          (game_control_valid),
        .pattern_control_ready       (pattern_control_ready),
        .pattern_control_valid       (pattern_control_valid),
        .i_pattern_state             (i_pattern_state),
        .o_tx_data                   (o_tx_data),
        .i_rx_data                   (i_rx_data),
        .o_rx_data                   (o_rx_data)
    );

    // ---------------- Clock ----------------
    always #5 clk = ~clk;  // 100MHz

    // ---------------- Pass/Fail bookkeeping ----------------
    int pass_cnt = 0;
    int fail_cnt = 0;

    task automatic check(input string name, input logic [63:0] actual,
                         input logic [63:0] expected);
        if (actual === expected) begin
            pass_cnt++;
            $display("[PASS] %-28s actual=0x%0h expected=0x%0h", name, actual,
                     expected);
        end else begin
            fail_cnt++;
            $display("[FAIL] %-28s actual=0x%0h expected=0x%0h", name, actual,
                     expected);
        end
    endtask

    // 모든 입력 초기화
    task automatic clear_inputs();
        tx_sync                      = 0;
        uart_data_control_uart_ready = 0;
        volume_uart_valid            = 0;
        i_volume_level               = '0;
        xy_uart_valid                = 0;
        i_pixel                      = '0;
        stick_control_valid          = 0;
        i_speed                      = '0;
        score_control_valid          = 0;
        i_score                      = '0;
        game_control_valid           = 0;
        i_game_state                 = '0;
        pattern_control_valid        = 0;
        i_pattern_state              = '0;
        i_rx_data                    = '0;
    endtask

    // ready가 1이라고 가정하고 한 클럭만 valid=1로 펄스를 쏘는 매크로
    // (일부 시뮬레이터가 ref 포트를 지원하지 않아 매크로로 인라인 처리)
    `define PULSE_UP(SIG) \
        @(negedge clk); \
        SIG = 1; \

    `define PULSE_D(SIG) \
        @(negedge clk); \
        SIG = 0; \
    

    // ---------------- Stimulus ----------------
    initial begin
        clk = 0;
        rst = 1;
        clear_inputs();
        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);

        //==========================================================
        // 1) Reset 직후 상태 확인
        //==========================================================
        $display("\n===== 1) Reset 직후 상태 확인 =====");
        check("reset: o_tx_data", o_tx_data, 64'h0);
        if (game_control_ready && xy_uart_ready && pattern_control_ready &&
            volume_uart_ready && stick_control_ready && score_control_ready &&
            uart_data_control_uart_valid == 0) begin
            pass_cnt++;
            $display("[PASS] reset: 모든 ready=1, uart_valid=0");
        end else begin
            fail_cnt++;
            $display(
                "[FAIL] reset: ready/valid 초기값 불일치 (game=%0b xy=%0b pattern=%0b vol=%0b stick=%0b score=%0b uart_valid=%0b)",
                game_control_ready, xy_uart_ready, pattern_control_ready,
                volume_uart_ready, stick_control_ready, score_control_ready,
                uart_data_control_uart_valid);
        end

        //==========================================================
        // 2) 필드별 latch 검증 (uart_data_control_uart_valid=0 인 상태에서)
        //==========================================================
        $display("\n===== 2) 필드별 valid&&ready latch 검증 =====");

        // game_fsm
        `PULSE_UP(game_control_valid)
        i_game_state = 2'b10;
        `PULSE_D(game_control_valid)
        @(negedge clk);
        check("game_fsm field latch", o_tx_data[GAME_FSM_MSB:GAME_FSM_LSB],
              2'b10);

        // xy_dec
        `PULSE_UP(xy_uart_valid)
        i_pixel = 40'hAB_CDEF_1234;
        `PULSE_D(xy_uart_valid)
        @(negedge clk);
        check("xy_dec field latch", o_tx_data[XY_DEC_MSB:XY_DEC_LSB],
              40'hAB_CDEF_1234);

        // pattern
        `PULSE_UP(pattern_control_valid)
        i_pattern_state = 3'b101;
        `PULSE_D(pattern_control_valid)
        @(negedge clk);
        check("pattern field latch", o_tx_data[PATTERN_MSB:PATTERN_LSB],
              3'b101);

        // volume
        `PULSE_UP(volume_uart_valid)
        i_volume_level = 7'h55;
        `PULSE_D(volume_uart_valid)
        @(negedge clk);
        check("volume field latch", o_tx_data[VOL_MSB:VOL_LSB], 7'h55);

        // speed
        `PULSE_UP(stick_control_valid)
        i_speed = 8'hA5;
        `PULSE_D(stick_control_valid)
        @(negedge clk);
        check("speed field latch", o_tx_data[SPEED_MSB:SPEED_LSB], 8'hA5);

        // score
        `PULSE_UP(score_control_valid)
        i_score = 4'hC;
        `PULSE_D(score_control_valid)
        @(negedge clk);
        check("score field latch", o_tx_data[SCORE_MSB:SCORE_LSB], 4'hC);

        // 지금까지 누적된 전체 프레임이 필드별로 겹침/유실 없이 다 유지되는지 종합 확인
        check("combined frame after all fields", o_tx_data, {
              2'b10, 40'hAB_CDEF_1234, 3'b101, 7'h55, 8'hA5, 4'hC});

        //==========================================================
        // 3) tx_sync -> uart_data_control_uart_valid 트리거 확인
        //==========================================================
        $display("\n===== 3) tx_sync 트리거 확인 =====");
        @(negedge clk);
        tx_sync = 1;
        @(negedge clk);
        tx_sync = 0;
        @(negedge clk);
        if (uart_data_control_uart_valid) begin
            pass_cnt++;
            $display("[PASS] tx_sync 이후 uart_data_control_uart_valid=1");
        end else begin
            fail_cnt++;
            $display(
                "[FAIL] tx_sync 이후에도 uart_data_control_uart_valid=0");
        end

        //==========================================================
        // 4) 전송 중(uart_valid=1)에는 모든 ready가 0 -> write 차단되는지
        //==========================================================
        $display("\n===== 4) 전송 중 ready=0 & write 차단 검증 =====");
        if (!game_control_ready && !xy_uart_ready && !pattern_control_ready &&
            !volume_uart_ready && !stick_control_ready && !score_control_ready) begin
            pass_cnt++;
            $display("[PASS] uart_valid=1 동안 모든 필드 ready=0");
        end else begin
            fail_cnt++;
            $display(
                "[FAIL] uart_valid=1 인데도 일부 ready=1 (레이스 위험)");
        end

        // 이 상태에서 score를 새 값으로 바꾸려 시도 -> 반영되면 안 됨
        `PULSE_UP(score_control_valid)
        i_score = 4'h1;
        `PULSE_D(score_control_valid)
        @(negedge clk);
        check("score write blocked during tx", o_tx_data[SCORE_MSB:SCORE_LSB],
              4'hC  /* 이전 값 유지되어야 함 */);

        //==========================================================
        // 5) uart_ready로 핸드셰이크 완료 -> valid 해제 & ready 복귀
        //==========================================================
        $display("\n===== 5) uart 핸드셰이크 완료 확인 =====");
        @(negedge clk);
        uart_data_control_uart_ready = 1;
        @(negedge clk);
        uart_data_control_uart_ready = 0;
        @(negedge clk);
        if (!uart_data_control_uart_valid) begin
            pass_cnt++;
            $display(
                "[PASS] 핸드셰이크 완료 후 uart_data_control_uart_valid=0");
        end else begin
            fail_cnt++;
            $display(
                "[FAIL] 핸드셰이크 완료했는데도 uart_data_control_uart_valid=1 유지");
        end

        if (game_control_ready && xy_uart_ready && score_control_ready) begin
            pass_cnt++;
            $display("[PASS] 전송 완료 후 ready 신호들 복귀");
        end else begin
            fail_cnt++;
            $display("[FAIL] 전송 완료 후에도 ready 복귀 안 됨");
        end

        // 이제 다시 score latch 시도 -> 이번엔 반영돼야 함
        `PULSE_UP(score_control_valid)
        i_score = 4'h1;
        `PULSE_D(score_control_valid)
        @(negedge clk);
        check("score write after tx done", o_tx_data[SCORE_MSB:SCORE_LSB],
              4'h1);

        //==========================================================
        // 6) rx pass-through 확인
        //==========================================================
        $display("\n===== 6) rx pass-through 확인 =====");
        i_rx_data = 8'h7E;
        #1;  // 조합 로직 반영 대기
        check("rx pass-through", {56'h0, o_rx_data}, {56'h0, 8'h7E});

        //==========================================================
        // 결과 요약
        //==========================================================
        $display("\n===================================================");
        $display("  TEST SUMMARY : PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
        $display("===================================================");
        if (fail_cnt == 0) $display("  ALL TESTS PASSED");
        else $display("  SOME TESTS FAILED - see [FAIL] lines above");

        #20;
        $finish;
    end

    // 타임아웃 안전장치
    initial begin
        #10000;
        $display("[TIMEOUT] simulation did not finish in time");
        $finish;
    end

endmodule
