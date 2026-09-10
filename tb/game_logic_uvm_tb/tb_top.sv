`timescale 1ns / 1ps

module tb_top;
    // Clock/reset 생성, DUT 연결, UVM 시작과 waveform 저장을 담당한다.
    import uvm_pkg::*;
    import game_logic_pkg::*;
    logic clk = 0;
    // 6 kHz clock과 30 FPS를 사용해 한 frame을 정확히 200 clocks로 표현한다.
    always #83_333 clk = ~clk;
    game_logic_if intf (clk);
    game_logic dut (
        .clk(clk),
        .rst(intf.rst),
        .i_stick_x_pixel(intf.i_stick_x_pixel),
        .i_stick_y_pixel(intf.i_stick_y_pixel),
        .i_hand_y_pixel(intf.i_hand_y_pixel),
        .i_vsync(intf.i_vsync),
        .i_pc_state(intf.i_pc_state),
        .i_pc_song(intf.i_pc_song),
        .pattern_control_ready(intf.pattern_control_ready),
        .stick_control_ready(intf.stick_control_ready),
        .volume_uart_ready(intf.volume_control_ready),
        .game_control_ready(intf.game_control_ready),
        .score_control_ready(intf.score_control_ready),
        .pattern_control_valid(intf.pattern_control_valid),
        .o_pattern_state(intf.o_pattern_state),
        .stick_control_valid(intf.stick_control_valid),
        .o_speed(intf.o_speed),
        .volume_uart_valid(intf.volume_control_valid),
        .o_volume_level(intf.o_volume_level),
        .game_control_valid(intf.game_control_valid),
        .o_game_state(intf.o_game_state),
        .score_control_valid(intf.score_control_valid),
        .o_score(intf.o_score)
    );
    defparam dut.u_speed_calc.CLK_FREQ = TB_CLK_FREQ;

    // Top port에서 빠진 내부 관찰 신호는 TB에서 읽기 전용으로 interface에 연결한다.
    assign intf.o_pattern_tick     = dut.w_pattern_tick;
    assign intf.score_pattern_tick = dut.w_score_pattern_tick;
    assign intf.state_change_enable = dut.w_state_change_enable;
    assign intf.o_game_start       = dut.w_game_start;
    assign intf.o_game_done        = dut.w_game_done;
    assign intf.o_score_en         = dut.w_score_en;
    assign intf.o_song_bpm         = dut.w_song_bpm;
    assign intf.o_song_num         = dut.u_song_decoder.o_song_num;
    assign intf.speed_ram[0]       = dut.u_game_score.speed_ram[0];
    assign intf.speed_ram[1]       = dut.u_game_score.speed_ram[1];
    assign intf.speed_ram[2]       = dut.u_game_score.speed_ram[2];
    assign intf.speed_ram[3]       = dut.u_game_score.speed_ram[3];
    assign intf.score_state        = dut.u_game_score.c_state;
    assign intf.score_tick_cnt     = dut.u_game_score.tick_cnt;

    // DUT 입력의 초기값을 넣고 reset을 해제한다.
    initial begin
        intf.rst = 1;
        intf.i_vsync = 0;
        intf.i_stick_x_pixel = 0;
        intf.i_stick_y_pixel = 0;
        intf.i_hand_y_pixel = 10'h3ff;
        intf.i_pc_state = PC_MAIN;
        intf.i_pc_song = 0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        intf.rst = 0;
    end
    // Interface를 UVM에 전달하고 선택된 test를 시작한다.
    initial begin
        uvm_config_db#(virtual game_logic_if)::set(null, "*", "vif", intf);
        run_test();
    end

    // 실행 옵션으로 지정된 파일에 Verdi용 FSDB waveform을 저장한다.
    initial begin
        string fsdb_file;
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_file))
            fsdb_file = "wave_game_logic.fsdb";
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_top);
        $fsdbDumpMDA();
    end

    property p_vsync_one_cycle;
        @(posedge clk) disable iff (intf.rst) intf.i_vsync |=> !intf.i_vsync;
    endproperty

    
    a_vsync_one_cycle :
    assert property (p_vsync_one_cycle);
    a_score_range :
    assert property (@(posedge clk) disable iff (intf.rst) intf.o_score <= 10);
    a_volume_range :
    assert property (@(posedge clk) disable iff (intf.rst) intf.o_volume_level <= 100);
endmodule
