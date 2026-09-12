`timescale 1ns/1ps
package game_logic_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 실제 시간 비율을 유지하면서 simulation cycle 수를 줄인 설정이다.
  localparam int TB_CLK_FREQ    = 6000;
  localparam int TB_FRAME_RATE  = 30;
  localparam int TB_FRAME_CYCLES = TB_CLK_FREQ / TB_FRAME_RATE;
  localparam int TB_MIN_BPM     = 30;
  localparam int TB_MAX_BPM     = 220;
  localparam int DEFAULT_SEQ_REPEAT = 3;

  localparam logic [2:0] PC_MAIN  = 0;
  localparam logic [2:0] PC_MENU  = 1;
  localparam logic [2:0] PC_READY = 2;
  localparam logic [2:0] PC_GAME  = 3;
  localparam logic [2:0] PC_STOP  = 4;

  localparam logic [2:0] P_IDLE  = 0;
  localparam logic [2:0] P_START = 1;
  localparam logic [2:0] P_READY = 2;
  localparam logic [2:0] P1      = 3;
  localparam logic [2:0] P2      = 4;
  localparam logic [2:0] P3      = 5;
  localparam logic [2:0] P4      = 6;
  localparam logic [2:0] P_STOP  = 7;

  // 한 번의 좌표 갱신에 필요한 stick/hand/PC 입력과 갱신 간격을 담는다.
  class game_logic_item extends uvm_sequence_item;
    rand logic [9:0] stick_x;
    rand logic [9:0] stick_y;
    rand logic [9:0] hand_y;

    logic [2:0] pc_state = PC_MAIN;
    logic [2:0] pc_song  = 0;
    int unsigned wait_frames = 1;

    `uvm_object_utils_begin(game_logic_item)
      `uvm_field_int(stick_x,     UVM_DEFAULT)
      `uvm_field_int(stick_y,     UVM_DEFAULT)
      `uvm_field_int(hand_y,      UVM_DEFAULT)
      `uvm_field_int(pc_state,    UVM_DEFAULT)
      `uvm_field_int(pc_song,     UVM_DEFAULT)
      `uvm_field_int(wait_frames, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "game_logic_item");
      super.new(name);
    endfunction
  endclass

  // 모든 directed sequence가 좌표 transaction을 만들도록 공통 put()을 제공한다.
  class game_logic_seq extends uvm_sequence #(game_logic_item);
    `uvm_object_utils(game_logic_seq)
    function new(string name = "game_logic_seq");
      super.new(name);
    endfunction

    task put(
      logic [9:0]  x,
      logic [9:0]  y,
      logic [9:0]  hand        = 10'd200,
      logic [2:0]  pc_state    = PC_GAME,
      logic [2:0]  song        = 0,
      int unsigned wait_frames = 1
    );
      game_logic_item item;

      item = game_logic_item::type_id::create("item");

      start_item(item);
      item.stick_x    = x;
      item.stick_y    = y;
      item.hand_y     = hand;
      item.pc_state   = pc_state;
      item.pc_song    = song;
      item.wait_frames = wait_frames;
      finish_item(item);
    endtask

    virtual task body();


    endtask
  endclass

  // 정상/비정상 좌표 순서와 zone 경계값으로 Conduct FSM을 확인한다.
  class conduct_seq extends game_logic_seq;
    `uvm_object_utils(conduct_seq)
    function new(string name = "conduct_seq");
      super.new(name);
    endfunction

    task body();
      // 시작 후 전체 상태, 반복/잘못된 입력, 정상 복귀와 경계값을 차례로 확인한다.
      put(10'd0, 10'd0, 10'd200, PC_READY, 1);
      put(160, 30);
      put(160, 200);
      put(160, 200);
      put(220, 135);
      put(0, 0);
      // 위의 3개 무효 입력까지 합쳐 P1 -> P2 간격을 18 frame으로 맞춘다.
      put(100, 135, 200, PC_GAME, 1, 15);
      put(160, 30);
      put(160, 200);
      put(139, 200);
      put(140, 175);
      put(125, 160);
      // 위의 5개 무효 입력까지 합쳐 P2 -> P3 간격을 18 frame으로 맞춘다.
      put(195, 110, 200, PC_GAME, 1, 13);
      put(180, 60,  200, PC_GAME, 1, 18);
      put(180, 240, 200, PC_GAME, 1, 18);

      // 다음 시행이 처음 상태부터 시작하도록 게임을 종료한다.
      put(0, 0, 200, PC_STOP, 1);
    endtask
  endclass

  // pattern tick 사이 간격을 바꿔 100/75/120 BPM 계산을 확인한다.
  class bpm_seq extends game_logic_seq;
    `uvm_object_utils(bpm_seq)
    function new(string name = "bpm_seq");
      super.new(name);
    endfunction

    task body();
      put(0, 0, 200, PC_READY, 1);
      put(160, 30);
      put(160, 200);

      // READY -> P1에서 측정을 시작한 뒤 100/75/120 BPM을 차례로 만든다.
      // 가장 빠른 120 BPM을 마지막에 두어 FAST 보정도 함께 확인한다.
      put(100, 135, 200, PC_GAME, 1, 18);
      put(220, 135, 200, PC_GAME, 1, 24);
      put(160, 30,  200, PC_GAME, 1, 15);

      // 다음 시행이 처음 상태부터 시작하도록 게임을 종료한다.
      put(0, 0, 200, PC_STOP, 1);
    endtask
  endclass

  // 정확하거나 크게 다른 BPM을 반복해 Score 증가와 감소를 확인한다.
  class score_seq extends game_logic_seq;
    `uvm_object_utils(score_seq)
    function new(string name = "score_seq");
      super.new(name);
    endfunction

    task body();
      int i;
      logic [9:0] xs[4] = '{100, 220, 160, 160};
      logic [9:0] ys[4] = '{135, 135, 30, 200};

      put(0, 0, 200, PC_READY, 1);
      put(160, 30);
      put(160, 200);

      // 100 BPM을 반복하여 Score가 증가하고 최대 10에서 유지되는지 확인한다.
      for (i = 0; i < 24; i++) begin
        put(xs[i % 4], ys[i % 4], 200, PC_GAME, 1, 18);
      end

      // 50 BPM을 반복하여 기준 BPM과의 차이 때문에 Score가 감소하는지 확인한다.
      for (i = 0; i < 12; i++) begin
        put(xs[i % 4], ys[i % 4], 200, PC_GAME, 1, 36);
      end

      // 다음 시행이 처음 상태부터 시작하도록 게임을 종료한다.
      put(0, 0, 200, PC_STOP, 1);
    endtask
  endclass

  // 곡 선택부터 게임 시작, 지휘, 볼륨 변경, 종료까지 전체 흐름을 실행한다.
  class full_game_seq extends game_logic_seq;
    `uvm_object_utils(full_game_seq)
    function new(string name = "full_game_seq");
      super.new(name);
    endfunction

    task body();
      int i;
      logic [9:0] xs[4] = '{100, 220, 160, 160};
      logic [9:0] ys[4] = '{135, 135, 30, 200};

      // 게임 준비 과정에서 모든 유효 곡 번호와 해당 BPM을 확인한다.
      for (i = 0; i < 5; i++) begin
        put(0, 0, 200, PC_READY, i);
      end

      // 실제 게임에서 사용할 2번 곡(120 BPM)을 마지막으로 다시 선택한다.
      put(0, 0, 200, PC_READY, 2);
      put(160, 30,  200, PC_GAME, 2);
      put(160, 200, 200, PC_GAME, 2);

      // 120 BPM 속도로 정상 지휘를 반복한다.
      for (i = 0; i < 12; i++) begin
        put(xs[i % 4], ys[i % 4], 200, PC_GAME, 2, 15);
      end

      // 손 기준점 설정, 위로 이동, 미검출, 재검출 순서로 Volume을 확인한다.
      for (i = 0; i < 31; i++) begin
        put(160, 200, 300, PC_GAME, 2, 1);
      end

      for (i = 0; i < 10; i++) begin
        put(160, 200, 200, PC_GAME, 2, 1);
      end

      for (i = 0; i < 10; i++) begin
        put(160, 200, 10'h3ff, PC_GAME, 2, 1);
      end

      for (i = 0; i < 31; i++) begin
        put(160, 200, 250, PC_GAME, 2, 1);
      end

      put(xs[0], ys[0], 250, PC_STOP, 2);
    endtask
  endclass

  // RTL의 정상 입력으로 도달 가능한 case/분기를 한 번의 test에서 모두 자극한다.
  class full_case_coverage_seq extends game_logic_seq;
    `uvm_object_utils(full_case_coverage_seq)
    function new(string name = "full_case_coverage_seq");
      super.new(name);
    endfunction

    // 지정한 pattern 상태까지 정상 진행한 뒤 PC_STOP으로 종료한다.
    task run_and_stop_at(logic [2:0] stop_state, logic [2:0] song = 1);
      put(0,   0,   200, PC_READY, song);
      put(160, 30,  200, PC_GAME,  song); // START -> READY
      put(160, 200, 200, PC_GAME,  song); // READY -> P1

      if (stop_state >= P2) put(100, 135, 200, PC_GAME, song);
      if (stop_state >= P3) put(220, 135, 200, PC_GAME, song);
      if (stop_state >= P4) put(160, 30,  200, PC_GAME, song);

      put(0, 0, 200, PC_STOP, song);
    endtask

    task body();
      int i;
      logic [9:0] xs[4] = '{100, 220, 160, 160};
      logic [9:0] ys[4] = '{135, 135, 30, 200};

      // Song decoder의 5개 정상 case와 default case를 모두 실행한다.
      for (i = 0; i < 8; i++) begin
        put(0, 0, 200, PC_READY, i);
      end

      put(139, 174, 200, PC_GAME, 1);
      put(181, 241, 200, PC_GAME, 1);
      put(140, 100, 200, PC_GAME, 1);
      put(100, 175, 200, PC_GAME, 1);
      put(140, 175, 200, PC_GAME, 1);
      put(180, 240, 200, PC_GAME, 1);
      put(74, 109, 200, PC_GAME, 1);
      put(126, 161, 200, PC_GAME, 1);
      put(75, 110, 200, PC_GAME, 1);
      put(125, 160, 200, PC_GAME, 1);
      put(194, 109, 200, PC_GAME, 1);
      put(246, 161, 200, PC_GAME, 1);
      put(195, 110, 200, PC_GAME, 1);
      put(245, 160, 200, PC_GAME, 1);
      put(139, 1, 200, PC_GAME, 1);
      put(181, 61, 200, PC_GAME, 1);
      put(140, 0, 200, PC_GAME, 1);
      put(180, 60, 200, PC_GAME, 1);

      // 마지막 정상 곡을 선택하고 P1에서 종료한다.
      put(0,   0,   200, PC_READY, 1);
      put(160, 30,  200, PC_GAME,  1);
      put(160, 200, 200, PC_GAME,  1);
      put(0,   0,   200, PC_GAME,  1, 1000);
      put(0,   0,   200, PC_STOP,  1);

      // pattern_stick의 P2/P3/P4별 game_stop 분기를 각각 실행한다.
      run_and_stop_at(P2);
      run_and_stop_at(P3);
      run_and_stop_at(P4);

      // Game FSM의 READY -> IDLE 종료 분기는 마지막에 둔다. 이 경로에서는
      // pattern FSM이 START에 머물기 때문에 이후 pattern 자극을 진행할 수 없다.
      // 그 전에 한 게임에서 Speed/Score/Volume의 모든 데이터 분기를 실행한다.
      put(0,   0,   200, PC_READY, 1); // 기준 곡: 100 BPM
      put(160, 30,  200, PC_GAME,  1);
      put(160, 200, 200, PC_GAME,  1);

      // 정확한 100 BPM으로 score를 10까지 올린다.
      for (i = 0; i < 24; i++) begin
        put(xs[i % 4], ys[i % 4], 200, PC_GAME, 1, 18);
      end

      // 50 BPM으로 score를 0까지 내리고 slow/NORMAL 경로를 실행한다.
      for (i = 0; i < 40; i++) begin
        put(xs[i % 4], ys[i % 4], 200, PC_GAME, 1, 36);
      end

      // 220 BPM clamp와 FAST 경로, 이어지는 NORMAL 경로를 실행한다.
      put(100, 135, 200, PC_GAME, 1, 6);
      put(220, 135, 200, PC_GAME, 1, 18);

      // TRACK 상태에서 100, 50, high, low, 0 volume bin을 순서대로 만든다.
      for (i = 0; i < 10; i++) put(220, 135,   0, PC_GAME, 1);
      for (i = 0; i < 10; i++) put(220, 135, 100, PC_GAME, 1);
      for (i = 0; i < 10; i++) put(220, 135,  40, PC_GAME, 1);
      for (i = 0; i < 10; i++) put(220, 135, 160, PC_GAME, 1);
      for (i = 0; i < 10; i++) put(220, 135, 400, PC_GAME, 1);

      put(0, 0, 10'h3ff, PC_STOP, 1);

      // game_fsm READY case의 PC_STOP 우선 분기를 실행하고 종료한다.
      put(0, 0, 10'h3ff, PC_READY, 1);
      put(0, 0, 10'h3ff, PC_STOP,  1);
    endtask
  endclass


  // 좌표와 VSYNC=1을 동시에 적용하고 다음 clock에 VSYNC만 0으로 내린다.
  class game_logic_driver extends uvm_driver #(game_logic_item);
    `uvm_component_utils(game_logic_driver)

    virtual game_logic_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual game_logic_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("DRV", "virtual interface를 찾을 수 없습니다.")
      end
    endfunction

    task run_phase(uvm_phase phase);
      game_logic_item item;
      int unsigned frame_index;
      int unsigned requested_frames;

      wait (!vif.rst);

      forever begin
        seq_item_port.get_next_item(item);

        `uvm_info(
          "DRV",
          $sformatf(
            "다음 입력: stick=(%0d,%0d), hand_y=%0d, pc_state=%0d, song=%0d, frame_gap=%0d",
            item.stick_x,
            item.stick_y,
            item.hand_y,
            item.pc_state,
            item.pc_song,
            item.wait_frames
          ),
          UVM_MEDIUM
        )

        // 잘못된 0 입력이 들어와도 최소 한 frame 간격은 유지한다.
        if (item.wait_frames == 0) begin
          requested_frames = 1;
        end else begin
          requested_frames = item.wait_frames;
        end

        // 좌표가 유지되는 동안에도 실제 영상 입력처럼 매 frame VSYNC를 발생시킨다.
        for (frame_index = 1; frame_index <= requested_frames; frame_index++) begin
          repeat (TB_FRAME_CYCLES - 1) begin
            @(posedge vif.clk);
          end
          

          // 매 frame마다 VSYNC를 발생시킨다.          
          // 마지막 frame에서는 다음 transaction의 새 좌표도 함께 적용한다.
          if (frame_index == requested_frames) begin
            vif.i_stick_x_pixel <= item.stick_x;
            vif.i_stick_y_pixel <= item.stick_y;
            vif.i_hand_y_pixel  <= item.hand_y;
            vif.i_pc_state      <= item.pc_state;
            vif.i_pc_song       <= item.pc_song;
          end

          vif.i_vsync <= 1'b1;

          // 다음 posedge에서 VSYNC만 내리므로 high 폭은 정확히 1 clock이다.
          @(posedge vif.clk);
          vif.i_vsync <= 1'b0;
        end

        `uvm_info("DRV", "새 좌표와 frame VSYNC를 전달했습니다.", UVM_HIGH)

        seq_item_port.item_done();
      end
    endtask
  endclass



  // Monitor가 관찰한 DUT 신호의 한 clock snapshot을 저장한다.
  class game_logic_sample extends uvm_sequence_item;
    logic rst;
    logic vsync;
    logic pattern_tick;
    logic score_pattern_tick;
    logic state_change_enable;
    logic speed_valid;
    logic volume_valid;
    logic score_valid;
    logic game_start;
    logic game_done;
    logic score_enable;

    logic [2:0] pattern_state;
    logic [2:0] pc_state;
    logic [2:0] pc_song;
    logic [2:0] song_num;
    logic [1:0] game_state;
    logic [7:0] speed;
    logic [7:0] song_bpm;
    logic [6:0] volume;
    logic [3:0] score;

    `uvm_object_utils(game_logic_sample)

    function new(string name = "game_logic_sample");
      super.new(name);
    endfunction
  endclass



  // DUT 신호를 관찰해 상태 변화와 출력 event를 Scoreboard로 전달한다.
  class game_logic_monitor extends uvm_monitor;
    `uvm_component_utils(game_logic_monitor)

    virtual game_logic_if vif;
    uvm_analysis_port #(game_logic_sample) analysis_port;

    logic [2:0] previous_pattern;
    logic [1:0] previous_game;
    bit previous_valid; //상태 변화를 출력하기 위해 이전 clock의 상태를 저장한 적이 있는지.

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual game_logic_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("MON", "virtual interface를 찾을 수 없습니다.")
      end
    endfunction

    task run_phase(uvm_phase phase);
      game_logic_sample sample;

      forever begin
        @(posedge vif.clk);
        #1ps;

        sample = game_logic_sample::type_id::create("sample");

        sample.rst                = vif.rst;
        sample.vsync              = vif.i_vsync;
        sample.pattern_tick       = vif.o_pattern_tick;
        sample.score_pattern_tick = vif.score_pattern_tick;
        sample.state_change_enable = vif.state_change_enable;
        sample.pattern_state      = vif.o_pattern_state;
        sample.pc_state           = vif.i_pc_state;
        sample.pc_song            = vif.i_pc_song;
        sample.game_state         = vif.o_game_state;
        sample.game_start         = vif.o_game_start;
        sample.game_done          = vif.o_game_done;
        sample.score_enable       = vif.o_score_en;
        sample.speed_valid        = vif.stick_control_valid;
        sample.speed              = vif.o_speed;
        sample.volume_valid       = vif.volume_control_valid;
        sample.volume             = vif.o_volume_level;
        sample.score_valid        = vif.score_control_valid;
        sample.score              = vif.o_score;
        sample.song_num           = vif.o_song_num;
        sample.song_bpm           = vif.o_song_bpm;

        analysis_port.write(sample);

        if (!sample.rst) begin
          if (previous_valid && (sample.pattern_state != previous_pattern)) begin
            `uvm_info(
              "MON",
              $sformatf(
                "Pattern 상태 변화: %0d -> %0d, tick=%0b",
                previous_pattern,
                sample.pattern_state,
                sample.pattern_tick
              ),
              UVM_LOW
            )
          end

          if (previous_valid && (sample.game_state != previous_game)) begin
            `uvm_info(
              "MON",
              $sformatf(
                "Game 상태 변화: %0d -> %0d, start=%0b, done=%0b",
                previous_game,
                sample.game_state,
                sample.game_start,
                sample.game_done
              ),
              UVM_LOW
            )
          end

          if (sample.score_pattern_tick) begin
            `uvm_info("MON", $sformatf("BPM 출력: %0d", sample.speed), UVM_LOW)
          end

          if (sample.score_valid) begin
            `uvm_info("MON", $sformatf("Score 출력: %0d", sample.score), UVM_LOW)
          end

          if (sample.volume_valid) begin
            `uvm_info("MON", $sformatf("Volume 출력: %0d", sample.volume), UVM_LOW)
          end

          previous_pattern = sample.pattern_state;
          previous_game    = sample.game_state;
          previous_valid   = 1'b1;
        end else begin
          previous_valid = 1'b0;
        end
      end
    endtask
  endclass



  // FSM, BPM, Song mapping과 출력 범위를 비교해 PASS/FAIL을 집계한다.
  class game_logic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(game_logic_scoreboard)

    uvm_analysis_imp #(game_logic_sample, game_logic_scoreboard) analysis_imp;

    int total_count;
    int pass_count;
    int fail_count;

    int unsigned speed_count_cycles;
    int unsigned expected_speed;

    bit first_tick_received;
    bit previous_sample_valid;
    bit speed_check_pending;
    bit previous_score_valid;

    logic [2:0] previous_pattern_state;
    logic [2:0] previous_pc_state;
    logic [2:0] previous_pc_song;
    logic [1:0] previous_game_state;
    logic [3:0] previous_score;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_imp = new("analysis_imp", this);
    endfunction

    // 모든 비교 결과를 한곳에서 PASS/FAIL 카운터에 반영한다.
    function void compare_result(bit result, string message);
      total_count++;

      if (result) begin
        pass_count++;
        `uvm_info("SCB", $sformatf("PASS: %s", message), UVM_HIGH)
      end else begin
        fail_count++;
        `uvm_error("SCB", $sformatf("FAIL: %s", message))
      end
    endfunction

    // RTL과 같이 BPM을 30~220으로 제한한 뒤 가장 가까운 5 단위로 맞춘다.
    function int unsigned normalize_speed(int unsigned raw_speed);
      int unsigned limited_speed;

      if (raw_speed < TB_MIN_BPM) begin
        limited_speed = TB_MIN_BPM;
      end else if (raw_speed > TB_MAX_BPM) begin
        limited_speed = TB_MAX_BPM;
      end else begin
        limited_speed = raw_speed;
      end

      return ((limited_speed + 2) / 5) * 5;
    endfunction

    // 이전 Conduct 상태에서 현재 상태로 이동할 수 있는지 반환한다.
    function bit is_legal_pattern_transition(
      logic [2:0] previous_state,
      logic [2:0] current_state
    );
      if (previous_state == current_state) begin
        return 1'b1;
      end

      case (previous_state)
        P_IDLE:  return (current_state == P_START);
        P_START: return (current_state == P_READY);
        P_READY: return (current_state == P1);
        P1:      return (current_state inside {P2, P_STOP});
        P2:      return (current_state inside {P3, P_STOP});
        P3:      return (current_state inside {P4, P_STOP});
        P4:      return (current_state inside {P1, P_STOP});
        P_STOP:  return (current_state == P_IDLE);
        default: return 1'b0;
      endcase
    endfunction

    // Game FSM의 허용된 상태 이동인지 반환한다.
    function bit is_legal_game_transition(
      logic [1:0] previous_state,
      logic [1:0] current_state
    );
      if (previous_state == current_state) begin
        return 1'b1;
      end

      case (previous_state)
        2'd0:   return (current_state == 2'd1);
        2'd1:   return (current_state inside {2'd0, 2'd2});
        2'd2:   return (current_state == 2'd0);
        default: return 1'b0;
      endcase
    endfunction

    // Monitor가 보낸 한 clock의 결과를 받아 핵심 동작을 검사한다.
    function void write(game_logic_sample sample);
      int unsigned expected_song_bpm;

      if (sample.rst) begin
        previous_sample_valid = 1'b0;
        first_tick_received   = 1'b0;
        speed_check_pending   = 1'b0;
        speed_count_cycles    = 0;
        previous_score_valid  = 1'b0;
        return;
      end

      compare_result(
        sample.score <= 10,
        $sformatf("Score 범위: actual=%0d, maximum=10", sample.score)
      );

      compare_result(
        sample.volume <= 100,
        $sformatf("Volume 범위: actual=%0d, maximum=100", sample.volume)
      );

      // 새 Speed FSM은 계산이 끝난 score용 tick에서 BPM을 출력한다.
      if (speed_check_pending && sample.score_pattern_tick) begin
        `uvm_info(
          "SCB",
          $sformatf(
            "BPM 비교: expected=%0d, actual=%0d",
            expected_speed[7:0],
            sample.speed
          ),
          UVM_MEDIUM
        )

        compare_result(
          sample.speed == expected_speed[7:0],
          $sformatf(
            "BPM expected=%0d, actual=%0d",
            expected_speed[7:0],
            sample.speed
          )
        );

        speed_check_pending = 1'b0;
      end

      if (previous_sample_valid) begin
        compare_result(
          is_legal_pattern_transition(previous_pattern_state, sample.pattern_state),
          $sformatf(
            "Conduct FSM 전이: %0d -> %0d",
            previous_pattern_state,
            sample.pattern_state
          )
        );

        if (sample.pattern_tick) begin
          compare_result(
            sample.pattern_state != previous_pattern_state,
            "상태 변화 없이 pattern_tick이 발생했습니다."
          );
        end

        compare_result(
          is_legal_game_transition(previous_game_state, sample.game_state),
          $sformatf(
            "Game FSM 전이: %0d -> %0d",
            previous_game_state,
            sample.game_state
          )
        );
      end

      // FAST/NORMAL 동안 멈춘 시간을 제외하고 RTL의 COUNT 구간만 센다.
      if (first_tick_received &&
          sample.state_change_enable &&
          (sample.pattern_state inside {P1, P2, P3, P4})) begin
        speed_count_cycles++;
      end

      // READY -> P1 tick은 측정 시작점이며, 다음 active tick부터 BPM을 계산한다.
      if (sample.pattern_tick &&
          (sample.pattern_state inside {P1, P2, P3, P4})) begin
        if (!first_tick_received) begin
          first_tick_received = 1'b1;
          speed_count_cycles  = 0;
        end else begin
          if (speed_count_cycles == 0) begin
            expected_speed = TB_MAX_BPM;
          end else begin
            expected_speed = normalize_speed(
              (60 * TB_CLK_FREQ) / speed_count_cycles
            );
          end

          speed_count_cycles  = 0;
          speed_check_pending = 1'b1;
        end
      end

      // 게임 밖으로 나오면 다음 지휘의 첫 tick부터 다시 측정한다.
      if (sample.pattern_state inside {P_IDLE, P_START, P_READY, P_STOP}) begin
        first_tick_received = 1'b0;
        speed_check_pending = 1'b0;
        speed_count_cycles  = 0;
      end

      // Song Decoder는 posedge 레지스터이므로 이전 clock의 PC 입력과 현재 출력을 비교한다.
      if (previous_sample_valid && (previous_pc_state == PC_READY)) begin
        if (previous_pc_song <= 4) begin
          expected_song_bpm = 80 + (20 * previous_pc_song);
        end else begin
          expected_song_bpm = 0;
        end

        compare_result(
          sample.song_num == previous_pc_song,
          $sformatf(
            "Song number expected=%0d, actual=%0d",
            previous_pc_song,
            sample.song_num
          )
        );

        compare_result(
          sample.song_bpm == expected_song_bpm,
          $sformatf(
            "Song BPM expected=%0d, actual=%0d",
            expected_song_bpm,
            sample.song_bpm
          )
        );
      end

      // 게임이 끝나면 다음 시행의 Score를 이전 게임과 이어서 비교하지 않는다.
      if (!sample.score_enable) begin
        previous_score_valid = 1'b0;
      end

      if (sample.score_valid) begin
        `uvm_info(
          "SCB",
          $sformatf(
            "Score 확인: previous=%0d, actual=%0d",
            previous_score,
            sample.score
          ),
          UVM_MEDIUM
        )

        if (previous_score_valid) begin
          compare_result(
            (sample.score == previous_score)     ||
            (sample.score == previous_score + 1) ||
            (sample.score + 1 == previous_score),
            $sformatf(
              "Score가 한 단계보다 크게 변경됨: %0d -> %0d",
              previous_score,
              sample.score
            )
          );
        end

        previous_score       = sample.score;
        previous_score_valid = 1'b1;
      end

      previous_pattern_state = sample.pattern_state;
      previous_pc_state      = sample.pc_state;
      previous_pc_song       = sample.pc_song;
      previous_game_state    = sample.game_state;
      previous_sample_valid  = 1'b1;
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      `uvm_info(
        "SCB",
        $sformatf(
          "최종 결과: Total=%0d, PASS=%0d, FAIL=%0d",
          total_count,
          pass_count,
          fail_count
        ),
        UVM_NONE
      )
    endfunction
  endclass

  // Monitor의 snapshot을 받아 주요 상태와 출력 값이 실제로 발생했는지 측정한다.
  class game_logic_coverage extends uvm_subscriber #(game_logic_sample);
    `uvm_component_utils(game_logic_coverage)

    game_logic_sample sample_data;

    covergroup game_logic_cg;
      option.per_instance = 1;

      // Conduct FSM의 모든 상태 방문 여부를 확인한다.
      cp_pattern_state: coverpoint sample_data.pattern_state {
        bins idle      = {P_IDLE};
        bins start     = {P_START};
        bins ready     = {P_READY};
        bins pattern_1 = {P1};
        bins pattern_2 = {P2};
        bins pattern_3 = {P3};
        bins pattern_4 = {P4};
        bins stop      = {P_STOP};
      }

      // 각 pattern case에서 실제로 수행한 정상 상태 전이를 확인한다.
      cp_pattern_transition: coverpoint sample_data.pattern_state {
        bins idle_to_start = (P_IDLE => P_START);
        bins start_to_ready = (P_START => P_READY);
        bins ready_to_p1 = (P_READY => P1);
        bins p1_to_p2 = (P1 => P2);
        bins p2_to_p3 = (P2 => P3);
        bins p3_to_p4 = (P3 => P4);
        bins p4_to_p1 = (P4 => P1);
        bins p1_to_stop = (P1 => P_STOP);
        bins p2_to_stop = (P2 => P_STOP);
        bins p3_to_stop = (P3 => P_STOP);
        bins p4_to_stop = (P4 => P_STOP);
        bins stop_to_idle = (P_STOP => P_IDLE);
      }

      // Game FSM의 IDLE, READY, GAME_ING 상태 방문 여부를 확인한다.
      cp_game_state: coverpoint sample_data.game_state {
        bins idle     = {0};
        bins ready    = {1};
        bins game_ing = {2};
        illegal_bins invalid = {3};
      }


      cp_game_transition: coverpoint sample_data.game_state {
        bins idle_to_ready = (0 => 1);
        bins ready_to_game = (1 => 2);
        bins ready_to_idle = (1 => 0);
        bins game_to_idle = (2 => 0);
      }

      // 유효한 BPM 출력이 느림/곡 범위/빠름 영역에 들어왔는지 확인한다.
      cp_bpm: coverpoint sample_data.speed iff (sample_data.score_pattern_tick) {
        bins slow       = {[TB_MIN_BPM:79]};
        bins song_range = {[80:160]};
        bins fast       = {[161:TB_MAX_BPM]};
        illegal_bins out_of_range = {[0:TB_MIN_BPM-1],
                                     [TB_MAX_BPM+1:255]};
      }

      // Score 출력의 최소, 초기, 중간, 최대 영역을 확인한다.
      cp_score: coverpoint sample_data.score iff (sample_data.score_valid) {
        bins minimum = {0};
        bins low     = {[1:4]};
        bins initial_score = {5};
        bins high    = {[6:9]};
        bins maximum = {10};
      }

      // Volume 출력의 최소, 중간, 최대 영역을 확인한다.
      cp_volume: coverpoint sample_data.volume iff (sample_data.volume_valid) {
        bins minimum = {0};
        bins low     = {[1:49]};
        bins middle  = {50};
        bins high    = {[51:99]};
        bins maximum = {100};
      }

      // Song decoder의 정상 case와 default case 입력을 모두 확인한다.
      cp_song: coverpoint sample_data.song_num iff (sample_data.pc_state == PC_READY) {
        bins valid_song[] = {[0:4]};
        bins default_song[] = {[5:7]};
      }
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      game_logic_cg = new();
    endfunction

    function void write(game_logic_sample t);
      sample_data = t;

      if (!t.rst) begin
        game_logic_cg.sample();
      end
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      `uvm_info(
        "COV",
        $sformatf(
          "Functional Coverage = %.2f%%",
          game_logic_cg.get_inst_coverage()
        ),
        UVM_NONE
      )
    endfunction
  endclass

  // Sequencer, Driver, Monitor를 하나의 입력 Agent로 묶는다.
  class game_logic_agent extends uvm_agent;
    `uvm_component_utils(game_logic_agent)

    uvm_sequencer #(game_logic_item) sequencer;
    game_logic_driver driver;
    game_logic_monitor monitor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      sequencer = new("sequencer", this);
      driver = game_logic_driver::type_id::create("driver", this);
      monitor = game_logic_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  // Agent의 Monitor 출력과 Scoreboard 입력을 연결한다.
  class game_logic_env extends uvm_env;
    `uvm_component_utils(game_logic_env)

    game_logic_agent agent;
    game_logic_scoreboard scoreboard;
    game_logic_coverage coverage;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      agent = game_logic_agent::type_id::create("agent", this);
      scoreboard = game_logic_scoreboard::type_id::create("scoreboard", this);
      coverage = game_logic_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      agent.monitor.analysis_port.connect(scoreboard.analysis_imp);
      agent.monitor.analysis_port.connect(coverage.analysis_export);
    endfunction
  endclass

  // 공통 환경을 생성하고 reset 이후 선택된 directed sequence를 실행한다.
  class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    game_logic_env env;
    virtual game_logic_if vif;
    int unsigned sequence_repeat_count;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = game_logic_env::type_id::create("env", this);

      sequence_repeat_count = DEFAULT_SEQ_REPEAT;
      void'($value$plusargs("SEQ_REPEAT=%d", sequence_repeat_count));

      if (sequence_repeat_count == 0) begin
        `uvm_warning("TEST", "SEQ_REPEAT=0은 사용할 수 없어 1회로 변경합니다.")
        sequence_repeat_count = 1;
      end

      if (!uvm_config_db#(virtual game_logic_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("TEST", "virtual interface를 찾을 수 없습니다.")
      end
    endfunction

    task run_one(uvm_sequence #(game_logic_item) sequence_to_run);
      `uvm_info("TEST", "Reset 해제를 기다립니다.", UVM_LOW)

      wait (!vif.rst);

      `uvm_info(
        "TEST",
        $sformatf("%s sequence를 시작합니다.", sequence_to_run.get_type_name()),
        UVM_LOW
      )

      sequence_to_run.start(env.agent.sequencer);

      repeat (8) begin
        @(posedge vif.clk);
      end

      `uvm_info("TEST", "Sequence가 종료되었습니다.", UVM_LOW)
    endtask
  endclass

  // Conduct FSM용 sequence를 실행하는 test이다.
  class conduct_fsm_test extends base_test;
    `uvm_component_utils(conduct_fsm_test)

    function new(string name = "conduct_fsm_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      conduct_seq sequence_to_run;
      int unsigned run_index;

      phase.raise_objection(this);
      for (run_index = 0; run_index < sequence_repeat_count; run_index++) begin
        `uvm_info(
          "TEST",
          $sformatf("Conduct 시행 %0d/%0d", run_index + 1, sequence_repeat_count),
          UVM_LOW
        )
        sequence_to_run = conduct_seq::type_id::create(
          $sformatf("sequence_to_run_%0d", run_index)
        );
        run_one(sequence_to_run);
      end
      phase.drop_objection(this);
    endtask
  endclass

  // BPM 계산용 sequence를 실행하는 test이다.
  class bpm_calc_test extends base_test;
    `uvm_component_utils(bpm_calc_test)

    function new(string name = "bpm_calc_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bpm_seq sequence_to_run;
      int unsigned run_index;

      phase.raise_objection(this);
      for (run_index = 0; run_index < sequence_repeat_count; run_index++) begin
        `uvm_info(
          "TEST",
          $sformatf("BPM 시행 %0d/%0d", run_index + 1, sequence_repeat_count),
          UVM_LOW
        )
        sequence_to_run = bpm_seq::type_id::create(
          $sformatf("sequence_to_run_%0d", run_index)
        );
        run_one(sequence_to_run);
      end
      phase.drop_objection(this);
    endtask
  endclass

  // Score 계산용 sequence를 실행하는 test이다.
  class score_test extends base_test;
    `uvm_component_utils(score_test)

    function new(string name = "score_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      score_seq sequence_to_run;
      int unsigned run_index;

      phase.raise_objection(this);
      for (run_index = 0; run_index < sequence_repeat_count; run_index++) begin
        `uvm_info(
          "TEST",
          $sformatf("Score 시행 %0d/%0d", run_index + 1, sequence_repeat_count),
          UVM_LOW
        )
        sequence_to_run = score_seq::type_id::create(
          $sformatf("sequence_to_run_%0d", run_index)
        );
        run_one(sequence_to_run);
      end
      phase.drop_objection(this);
    endtask
  endclass

  class speed_ram_debug_seq extends game_logic_seq;
    `uvm_object_utils(speed_ram_debug_seq)

    function new(string name = "speed_ram_debug_seq");
      super.new(name);
    endfunction

    task body();
      put(0, 0, 200, PC_READY, 1);
      put(160, 30, 200, PC_GAME, 1);
      put(160, 200, 200, PC_GAME, 1);

      put(100, 135, 200, PC_GAME, 1, 18);
      put(220, 135, 200, PC_GAME, 1, 24);
      put(160, 30,  200, PC_GAME, 1, 36);
      put(160, 200, 200, PC_GAME, 1, 15);

      put(160, 200, 200, PC_GAME, 1, 10);
    endtask
  endclass

  // 전체 게임 흐름용 sequence를 실행하는 test이다.
  class full_game_scenario_test extends base_test;
    `uvm_component_utils(full_game_scenario_test)

    function new(
      string name = "full_game_scenario_test",
      uvm_component parent = null
    );
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      full_game_seq sequence_to_run;
      int unsigned run_index;

      phase.raise_objection(this);
      for (run_index = 0; run_index < sequence_repeat_count; run_index++) begin
        `uvm_info(
          "TEST",
          $sformatf("Full 시행 %0d/%0d", run_index + 1, sequence_repeat_count),
          UVM_LOW
        )
        sequence_to_run = full_game_seq::type_id::create(
          $sformatf("sequence_to_run_%0d", run_index)
        );
        run_one(sequence_to_run);
      end
      phase.drop_objection(this);
    endtask
  endclass

  class speed_ram_debug_test extends base_test;
    `uvm_component_utils(speed_ram_debug_test)

    function new(
      string name = "speed_ram_debug_test",
      uvm_component parent = null
    );
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      speed_ram_debug_seq sequence_to_run;

      phase.raise_objection(this);
      sequence_to_run = speed_ram_debug_seq::type_id::create("sequence_to_run");
      run_one(sequence_to_run);
      phase.drop_objection(this);
    endtask
  endclass

  // 모든 정상 도달 가능 case/분기를 한 번에 자극하는 coverage test이다.
  class full_case_coverage_test extends base_test;
    `uvm_component_utils(full_case_coverage_test)

    function new(
      string name = "full_case_coverage_test",
      uvm_component parent = null
    );
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      full_case_coverage_seq sequence_to_run;

      phase.raise_objection(this);
      sequence_to_run = full_case_coverage_seq::type_id::create(
        "sequence_to_run"
      );
      run_one(sequence_to_run);
      phase.drop_objection(this);
    endtask
  endclass

endpackage
