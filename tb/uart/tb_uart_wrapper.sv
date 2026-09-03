`timescale 1ns / 1ps
//==============================================================
// tb_uart_wrapper.sv
// uart_wrapper TX/RX 통합 검증(self-checking) 테스트벤치
//
// 검증 항목
//  1) 6개 field를 취합한 64-bit packet의 UART TX 결과
//  2) UART RX로 입력한 1-byte 데이터의 wrapper 출력 결과
//==============================================================

module tb_uart_wrapper ();

    // ---------------- DUT I/O ----------------
    logic clk, rst;
    logic        pixel_dec_sync;

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

    logic [ 7:0] o_rx_data;
    logic        tx;
    logic        rx;

    // ---------------- Bit-map (DUT와 동일하게 재정의: 참조용) ----------------
    localparam GAME_FSM_MSB = 63, GAME_FSM_LSB = 62;
    localparam XY_DEC_MSB = 61, XY_DEC_LSB = 22;
    localparam PATTERN_MSB = 21, PATTERN_LSB = 19;
    localparam VOL_MSB = 18, VOL_LSB = 12;
    localparam SPEED_MSB = 11, SPEED_LSB = 4;
    localparam SCORE_MSB = 3, SCORE_LSB = 0;

    // ---------------- DUT instantiation ----------------
    uart_wrapper dut (
        .clk                  (clk),
        .rst                  (rst),
        .pixel_dec_sync       (pixel_dec_sync),
        .volume_uart_ready    (volume_uart_ready),
        .i_volume_level       (i_volume_level),
        .volume_uart_valid    (volume_uart_valid),
        .xy_uart_ready        (xy_uart_ready),
        .i_pixel              (i_pixel),
        .xy_uart_valid        (xy_uart_valid),
        .stick_control_ready  (stick_control_ready),
        .i_speed              (i_speed),
        .stick_control_valid  (stick_control_valid),
        .score_control_ready  (score_control_ready),
        .i_score              (i_score),
        .score_control_valid  (score_control_valid),
        .game_control_ready   (game_control_ready),
        .i_game_state         (i_game_state),
        .game_control_valid   (game_control_valid),
        .pattern_control_ready(pattern_control_ready),
        .pattern_control_valid(pattern_control_valid),
        .i_pattern_state      (i_pattern_state),
        .o_rx_data            (o_rx_data),
        .rx                   (rx),
        .tx                   (tx)
    );

    // ---------------- Clock ----------------
    always #5 clk = ~clk;  // 100MHz

    // ---------------- sync -----------------
    localparam int CLK_FREQ_HZ = 100_000_000;
    localparam int FRAME_HZ = 30;
    localparam int FRAME_CYCLES = CLK_FREQ_HZ / FRAME_HZ;
    localparam int BAUD_RATE = 115_200;
    localparam int SAMPLE = 16;
    localparam int SAMPLE_PERIOD = CLK_FREQ_HZ / BAUD_RATE / SAMPLE;
    localparam int BIT_PERIOD = SAMPLE_PERIOD * SAMPLE;


    initial begin
        pixel_dec_sync = 1'b0;

        wait (rst === 1'b0);

        forever begin
            repeat (FRAME_CYCLES - 1) @(posedge clk);

            pixel_dec_sync = 1'b1;
            @(posedge clk);

            pixel_dec_sync = 1'b0;
        end
    end
    // ---------------- Pass/Fail bookkeeping ----------------
    int pass_cnt = 0;
    int fail_cnt = 0;
    logic [63:0] tx_golden_queue[$];
    logic [ 7:0] rx_golden_queue[$];

    // 모든 입력 초기화
    task automatic clear_inputs();
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
        rx                           = 1;
    endtask

    // ready가 1이라고 가정하고 한 클럭만 valid=1로 펄스를 쏘는 매크로
    // (일부 시뮬레이터가 ref 포트를 지원하지 않아 매크로로 인라인 처리)
    `define PULSE_UP(SIG) \
        @(negedge clk); \
        SIG = 1; \

    `define PULSE_D(SIG) \
        @(negedge clk); \
        SIG = 0; \
    
    task automatic field_data_drive(int num);
        logic [63:0] golden_packet;

        repeat (num) begin
            wait(pixel_dec_sync);
            @(posedge clk);
            // game_fsm
            `PULSE_UP(game_control_valid)
            i_game_state = 2'b10;
            `PULSE_D(game_control_valid)
            @(negedge clk);

            // xy_dec
            `PULSE_UP(xy_uart_valid)
            i_pixel = 40'hAB_CDEF_1234;
            `PULSE_D(xy_uart_valid)
            @(negedge clk);

            // pattern
            `PULSE_UP(pattern_control_valid)
            i_pattern_state = 3'b101;
            `PULSE_D(pattern_control_valid)
            @(negedge clk);

            // volume
            `PULSE_UP(volume_uart_valid)
            i_volume_level = 7'h55;
            `PULSE_D(volume_uart_valid)
            @(negedge clk);

            // speed
            `PULSE_UP(stick_control_valid)
            i_speed = 8'hA5;
            `PULSE_D(stick_control_valid)
            @(negedge clk);

            // score
            `PULSE_UP(score_control_valid)
            i_score = 4'hC;
            `PULSE_D(score_control_valid)
            @(negedge clk);

            golden_packet = {2'b10, 40'hAB_CDEF_1234, 3'b101,
                             7'h55, 8'hA5, 4'hC};
            tx_golden_queue.push_back(golden_packet);
        end
    endtask

    task automatic TX_SCB(int num);
        logic [ 7:0] rx_byte;
        logic [63:0] actual_packet;
        logic [63:0] expected_packet;

        repeat (num) begin
            actual_packet = '0;

            for (int byte_idx = 0; byte_idx < 8; byte_idx++) begin
                @(negedge tx);
                repeat (BIT_PERIOD + BIT_PERIOD / 2) @(posedge clk);

                for (int bit_idx = 0; bit_idx < 8; bit_idx++) begin
                    rx_byte[bit_idx] = tx;
                    repeat (BIT_PERIOD) @(posedge clk);
                end

                actual_packet[byte_idx*8+:8] = rx_byte;
            end

            if (tx_golden_queue.size() == 0) begin
                fail_cnt++;
                $error("[TX_SCB FAIL] TX packet received, but golden queue is empty");
            end else begin
                expected_packet = tx_golden_queue.pop_front();
                if (actual_packet === expected_packet) begin
                    pass_cnt++;
                    $display("[%t]: [TX_SCB PASS] actual=0x%016h expected=0x%016h", $time,
                             actual_packet, expected_packet);
                end else begin
                    fail_cnt++;
                    $error("[%t]: [TX_SCB FAIL] actual=0x%016h expected=0x%016h", $time,
                           actual_packet, expected_packet);
                end
            end
        end
    endtask

    task automatic RX_DRV(input logic [7:0] data);
        logic [7:0] shift_data;

        shift_data = data;
        rx_golden_queue.push_back(data);

        rx = 1'b1;
        repeat (BIT_PERIOD) @(negedge clk);
        rx = 1'b0;
        repeat (BIT_PERIOD) @(negedge clk);

        for (int i = 0; i < 8; i++) begin
            rx = shift_data[0];
            shift_data = {1'b0, shift_data[7:1]};
            repeat (BIT_PERIOD) @(negedge clk);
        end

        rx = 1'b1;
        repeat (BIT_PERIOD) @(negedge clk);
    endtask

    task automatic RX_SCB(int num);
        logic [7:0] expected_data;

        repeat (num) begin
            wait (dut.U_UART.done == 1'b1);
            @(posedge clk);
            #1;

            if (rx_golden_queue.size() == 0) begin
                fail_cnt++;
                $error("[RX_SCB FAIL] RX done asserted, but golden queue is empty");
            end else begin
                expected_data = rx_golden_queue.pop_front();
                if (o_rx_data === expected_data) begin
                    pass_cnt++;
                    $display("[%t]: [RX_SCB PASS] actual=0x%02h expected=0x%02h", $time,
                             o_rx_data, expected_data);
                end else begin
                    fail_cnt++;
                    $error("[%t]: [RX_SCB FAIL] actual=0x%02h expected=0x%02h", $time,
                           o_rx_data, expected_data);
                end
            end
        end
    endtask

    // ---------------- Stimulus ----------------
    initial begin
        clk = 0;
        rst = 1;
        clear_inputs();
        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);

        fork
            field_data_drive(1);
            TX_SCB(1);
            RX_DRV(8'h5A);
            RX_SCB(1);
        join

        $display("[SUMMARY] pass=%0d fail=%0d", pass_cnt, fail_cnt);
        $finish;
    end

    // 타임아웃 안전장치
    initial begin
        #40_000_000;
        $display("[TIMEOUT] simulation did not finish in time");
        $finish;
    end

endmodule
