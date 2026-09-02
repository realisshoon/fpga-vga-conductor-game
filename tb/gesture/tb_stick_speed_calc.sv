`timescale 1ns / 1ps

module tb_stick_speed_calc;

    //==================================================
    // Parameter
    //==================================================
    // Simulation용
    //
    // 150 BPM → 280 clk
    // 120 BPM → 350 clk
    // 140 BPM → 300 clk
    //  50 BPM → 840 clk
    //==================================================
    localparam CLK_FREQ = 700;


    //==================================================
    // DUT Input
    //==================================================
    logic       clk;
    logic       rst;
    logic       i_vsync;
    logic       i_pattern_tick;
    logic [2:0] pattern_state;
    logic       stick_control_ready;


    //==================================================
    // DUT Output
    //==================================================
    logic       stick_control_valid;
    logic       o_pattern_tick;
    logic [7:0] o_speed;


    //==================================================
    // State
    //==================================================
    localparam IDLE      = 3'd0;
    localparam START     = 3'd1;
    localparam READY     = 3'd2;
    localparam PATTERN_1 = 3'd3;
    localparam PATTERN_2 = 3'd4;
    localparam PATTERN_3 = 3'd5;
    localparam PATTERN_4 = 3'd6;
    localparam STOP      = 3'd7;


    //==================================================
    // DUT
    //==================================================
    stick_speed_calc #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk                 (clk),
        .rst                 (rst),
        .i_vsync             (i_vsync),
        .i_pattern_tick      (i_pattern_tick),
        .pattern_state       (pattern_state),
        .stick_control_ready (stick_control_ready),

        .stick_control_valid (stick_control_valid),
        .o_pattern_tick      (o_pattern_tick),
        .o_speed             (o_speed)
    );


    //==================================================
    // Clock
    //==================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //==================================================
    // 상태 변경 + Pattern Tick 발생
    //==================================================
    task change_state_with_tick(
        input logic [2:0] next_state
    );
    begin

        @(negedge clk);

        pattern_state  = next_state;
        i_pattern_tick = 1'b1;

        // 다음 posedge에서 DUT가
        // state + tick을 동시에 확인
        @(negedge clk);

        i_pattern_tick = 1'b0;

    end
    endtask


    //==================================================
    // 현재 상태에서 Tick만 발생
    // START Tick 무시 테스트용
    //==================================================
    task pulse_pattern_tick;
    begin

        @(negedge clk);
        i_pattern_tick = 1'b1;

        @(negedge clk);
        i_pattern_tick = 1'b0;

    end
    endtask


    //==================================================
    // VSYNC Pulse
    //==================================================
    task pulse_vsync;
    begin

        @(negedge clk);
        i_vsync = 1'b1;

        @(negedge clk);
        i_vsync = 1'b0;

    end
    endtask


    //==================================================
    // Main Test
    //==================================================
    initial begin

        //==================================================
        // 초기화
        //==================================================
        rst                 = 1'b1;
        i_vsync             = 1'b0;
        i_pattern_tick      = 1'b0;
        pattern_state       = IDLE;
        stick_control_ready = 1'b0;

        repeat (5) @(posedge clk);

        rst = 1'b0;

        repeat (3) @(posedge clk);


        //==================================================
        // START
        //==================================================
        pattern_state = START;

        repeat (3) @(posedge clk);


        //==================================================
        // START에서 Tick 발생
        //
        // 이 Tick은 Speed 계산에 사용되면 안 됨
        //==================================================
        $display("");
        $display("====================================");
        $display("START TICK IGNORE TEST");
        $display("====================================");

        pulse_pattern_tick();

        repeat (20) @(posedge clk);

        $display("count_reg = %0d", dut.count_reg);
        $display("counting  = %0b", dut.counting);
        $display("o_speed   = %0d", o_speed);

        if ((dut.count_reg == 0) &&
            (dut.counting == 0))
            $display("[PASS] START tick ignored");
        else
            $display("[FAIL] START tick affected counter");


        //==================================================
        // READY
        //==================================================
        pattern_state = READY;

        repeat (3) @(posedge clk);


        //==================================================
        // PATTERN_1
        //
        // 첫 번째 유효 Tick
        // 여기서부터 속도 측정 시작
        //==================================================
        change_state_with_tick(PATTERN_1);

        $display("");
        $display("PATTERN_1 : Start Measurement");


        //==================================================
        // 1. PATTERN_1 → PATTERN_2
        //
        // 150 BPM
        //
        // 60 * 700 / 150 = 280 clock
        //
        // count_reg = 279
        // count_reg + 1 = 280
        //==================================================
        repeat (279) @(posedge clk);

        change_state_with_tick(PATTERN_2);

        #1;

        $display("");
        $display("====================================");
        $display("P1 -> P2 : 150 BPM");
        $display("====================================");
        $display("o_speed = %0d BPM", o_speed);
        $display("valid   = %0b", stick_control_valid);

        if (o_speed == 150)
            $display("[PASS] 150 BPM");
        else
            $display("[FAIL] Expected 150, Got %0d", o_speed);


        //==================================================
        // 2. PATTERN_2 → PATTERN_3
        //
        // 120 BPM
        //
        // 60 * 700 / 120 = 350 clock
        //==================================================
        repeat (349) @(posedge clk);

        change_state_with_tick(PATTERN_3);

        #1;

        $display("");
        $display("====================================");
        $display("P2 -> P3 : 120 BPM");
        $display("====================================");
        $display("o_speed = %0d BPM", o_speed);
        $display("valid   = %0b", stick_control_valid);

        if (o_speed == 120)
            $display("[PASS] 120 BPM");
        else
            $display("[FAIL] Expected 120, Got %0d", o_speed);


        //==================================================
        // 3. PATTERN_3 → PATTERN_4
        //
        // 140 BPM
        //
        // 60 * 700 / 140 = 300 clock
        //==================================================
        repeat (299) @(posedge clk);

        change_state_with_tick(PATTERN_4);

        #1;

        $display("");
        $display("====================================");
        $display("P3 -> P4 : 140 BPM");
        $display("====================================");
        $display("o_speed = %0d BPM", o_speed);
        $display("valid   = %0b", stick_control_valid);

        if (o_speed == 140)
            $display("[PASS] 140 BPM");
        else
            $display("[FAIL] Expected 140, Got %0d", o_speed);


        //==================================================
        // 4. PATTERN_4 → PATTERN_1
        //
        // 50 BPM
        //
        // 60 * 700 / 50 = 840 clock
        //==================================================
        repeat (839) @(posedge clk);

        change_state_with_tick(PATTERN_1);

        #1;

        $display("");
        $display("====================================");
        $display("P4 -> P1 : 50 BPM");
        $display("====================================");
        $display("o_speed = %0d BPM", o_speed);
        $display("valid   = %0b", stick_control_valid);

        if (o_speed == 50)
            $display("[PASS] 50 BPM");
        else
            $display("[FAIL] Expected 50, Got %0d", o_speed);


        //==================================================
        // VSYNC Test
        //
        // i_vsync = 1
        // → valid = 0
        //==================================================
        $display("");
        $display("====================================");
        $display("VSYNC VALID CLEAR TEST");
        $display("====================================");

        $display("Before VSYNC : valid = %0b",
                 stick_control_valid);

        pulse_vsync();

        #1;

        $display("After VSYNC  : valid = %0b",
                 stick_control_valid);

        if (stick_control_valid == 0)
            $display("[PASS] VSYNC cleared valid");
        else
            $display("[FAIL] valid still HIGH");


        //==================================================
        // Ready / Valid Test를 위해
        // 다시 120 BPM 데이터 생성
        //==================================================
        repeat (349) @(posedge clk);

        change_state_with_tick(PATTERN_2);

        #1;

        $display("");
        $display("New Speed = %0d BPM", o_speed);
        $display("Valid     = %0b", stick_control_valid);


        //==================================================
        // READY / VALID Handshake
        //
        // valid = 1
        // ready = 1
        // → valid = 0
        //==================================================
        $display("");
        $display("====================================");
        $display("READY / VALID HANDSHAKE TEST");
        $display("====================================");

        @(negedge clk);
        stick_control_ready = 1'b1;

        @(posedge clk);
        #1;

        $display("Speed = %0d BPM", o_speed);
        $display("Ready = %0b", stick_control_ready);
        $display("Valid = %0b", stick_control_valid);

        if (stick_control_valid == 0)
            $display("[PASS] Handshake completed");
        else
            $display("[FAIL] valid still HIGH");


        @(negedge clk);
        stick_control_ready = 1'b0;


        //==================================================
        // STOP
        //==================================================
        pattern_state = STOP;

        repeat (5) @(posedge clk);

        $display("");
        $display("====================================");
        $display("STOP TEST");
        $display("====================================");
        $display("count_reg = %0d", dut.count_reg);
        $display("counting  = %0b", dut.counting);


        //==================================================
        // END
        //==================================================
        repeat (10) @(posedge clk);

        $display("");
        $display("====================================");
        $display("SIMULATION END");
        $display("====================================");

        $finish;

    end

endmodule