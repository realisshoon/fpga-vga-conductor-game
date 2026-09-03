`timescale 1ns / 1ps

module tb_stick_speed_calc_0903;

    localparam CLK_FREQ = 100_000_000;

    localparam IDLE      = 3'd0;
    localparam READY     = 3'd2;
    localparam PATTERN_1 = 3'd3;
    localparam PATTERN_2 = 3'd4;
    localparam PATTERN_3 = 3'd5;
    localparam PATTERN_4 = 3'd6;
    localparam STOP      = 3'd7;

    localparam S_COUNT = 3'd2;
    localparam S_FAST  = 3'd3;

    logic clk, rst;
    logic i_vsync, i_pattern_tick;
    logic [2:0] i_pattern_state;
    logic [7:0] i_pc_song_bpm;
    logic stick_control_ready;

    logic stick_control_valid;
    logic o_pattern_tick;
    logic o_state_change_enable;
    logic [7:0] o_speed;

    stick_speed_calc #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk                   (clk),
        .rst                   (rst),
        .i_vsync               (i_vsync),
        .i_pattern_tick        (i_pattern_tick),
        .i_pattern_state       (i_pattern_state),
        .i_pc_song_bpm         (i_pc_song_bpm),
        .stick_control_ready   (stick_control_ready),
        .stick_control_valid   (stick_control_valid),
        .o_pattern_tick        (o_pattern_tick),
        .o_state_change_enable (o_state_change_enable),
        .o_speed               (o_speed)
    );

    always #5 clk = ~clk;

    // 1 clk pattern tick
    task tick(input logic [2:0] state);
    begin
        @(negedge clk);
        i_pattern_state = state;
        i_pattern_tick  = 1;

        @(negedge clk);
        i_pattern_tick  = 0;
    end
    endtask

    // 원하는 BPM의 count 후 tick
    task beat(input integer cnt, input logic [2:0] state);
    begin
        wait(dut.c_state == S_COUNT);
        wait(dut.count_reg == cnt-1);
        tick(state);
    end
    endtask

    task vsync;
    begin
        @(negedge clk);
        i_vsync = 1;
        @(negedge clk);
        i_vsync = 0;
    end
    endtask

    initial begin

        clk                 = 0;
        i_vsync             = 0;
        i_pattern_tick      = 0;
        i_pattern_state     = IDLE;
        stick_control_ready = 1;
        i_pc_song_bpm       = 8'd120;

        rst                 = 1;
        repeat(3) @(posedge clk);
        rst = 0;

        // READY → COUNT
        // 첫 출력 : 120 BPM
        @(negedge clk);
        i_pattern_state = READY;

        repeat(2) @(posedge clk);
        tick(PATTERN_1);

        // 120 → 120 : NORMAL
        // ready=1 → valid 다음 clk clear
        beat(50_000_000, PATTERN_2);

        // 120 → 60 : NORMAL
        // ready=0 → valid 유지
        stick_control_ready = 0;
        beat(100_000_000, PATTERN_3);

        repeat(3) @(posedge clk);

        // VSYNC → valid clear
        vsync();

        @(negedge clk);
        stick_control_ready = 1;

        // 60 → 150 : FAST
        // song_cnt=780, stick_cnt=312
        // FAST 대기 = 468 clk
        beat(40_000_000, PATTERN_4);

        wait(dut.c_state == S_FAST);

        // FAST 동안
        // count_reg = 0
        // time_count 증가
        // enable = 0

        wait(dut.c_state == S_COUNT);

        // FAST 종료 후
        // song_bpm = 150
        // song_cnt = 312
        // count_reg 다시 증가


        // 150 → 78 BPM
        // LUT : 78 → 80
        // o_speed = 80
        beat(76_923_076, PATTERN_1);

        repeat(3) @(posedge clk);

        // STOP → IDLE
        @(negedge clk);
        i_pattern_state = STOP;

        repeat(5) @(posedge clk);

        $finish;
    end

endmodule