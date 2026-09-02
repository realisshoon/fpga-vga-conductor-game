`timescale 1ns / 1ps

module tb_song_decoder;

    logic       clk;
    logic       rst;
    logic [2:0] i_pc_state;
    logic [2:0] i_pc_song;

    logic [2:0] o_song_num;
    logic [7:0] o_song_bpm;

    integer pass_count;
    integer fail_count;


    // PC State
    localparam MAIN        = 3'b000;
    localparam MENU        = 3'b001;
    localparam PC_READY    = 3'b010;
    localparam PC_GAME_ING = 3'b011;
    localparam PC_STOP     = 3'b100;


    // Song Number
    localparam SONG_0 = 3'b000;
    localparam SONG_1 = 3'b001;
    localparam SONG_2 = 3'b010;
    localparam SONG_3 = 3'b011;
    localparam SONG_4 = 3'b100;


    // Expected BPM
    localparam BPM_SONG_0 = 8'd80;
    localparam BPM_SONG_1 = 8'd100;
    localparam BPM_SONG_2 = 8'd120;
    localparam BPM_SONG_3 = 8'd140;
    localparam BPM_SONG_4 = 8'd160;


    // DUT
    song_decoder dut (
        .clk        (clk),
        .rst        (rst),
        .i_pc_state (i_pc_state),
        .i_pc_song  (i_pc_song),
        .o_song_num (o_song_num),
        .o_song_bpm (o_song_bpm)
    );


    // 100MHz Clock
    // Period = 10ns
    always #5 clk = ~clk;


    task check_output;
        input [2:0] expected_song_num;
        input [7:0] expected_song_bpm;
        input string test_name;

        begin
            #1;

            if ((o_song_num === expected_song_num) &&
                (o_song_bpm === expected_song_bpm)) begin

                pass_count = pass_count + 1;

                $display(
                    "[PASS] %s | state=%03b input_song=%03b | song_num=%0d bpm=%0d",
                    test_name,
                    i_pc_state,
                    i_pc_song,
                    o_song_num,
                    o_song_bpm
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "[FAIL] %s | state=%03b input_song=%03b | expected num=%0d bpm=%0d | got num=%0d bpm=%0d",
                    test_name,
                    i_pc_state,
                    i_pc_song,
                    expected_song_num,
                    expected_song_bpm,
                    o_song_num,
                    o_song_bpm
                );

            end
        end
    endtask


    initial begin

        clk        = 1'b0;
        rst        = 1'b0;
        i_pc_state = MAIN;
        i_pc_song  = SONG_0;

        pass_count = 0;
        fail_count = 0;


        // =====================================================
        // TEST 1 : ASYNC RESET
        // =====================================================

        #2;
        rst = 1'b1;

        check_output(
            3'b000,
            8'd0,
            "ASYNC RESET"
        );

        #2;
        rst = 1'b0;


        // =====================================================
        // TEST 2 : MAIN HOLD
        // MAIN에서는 input song이 변경되어도 출력 유지
        // =====================================================

        @(negedge clk);

        i_pc_state = MAIN;
        i_pc_song  = SONG_3;

        @(posedge clk);

        check_output(
            3'b000,
            8'd0,
            "MAIN HOLD"
        );


        // =====================================================
        // TEST 3 : MENU HOLD
        // MENU에서도 출력 유지
        // =====================================================

        @(negedge clk);

        i_pc_state = MENU;
        i_pc_song  = SONG_4;

        @(posedge clk);

        check_output(
            3'b000,
            8'd0,
            "MENU HOLD"
        );


        // =====================================================
        // TEST 4 : READY SONG 0
        // SONG 0 = 80 BPM
        // =====================================================

        @(negedge clk);

        i_pc_state = PC_READY;
        i_pc_song  = SONG_0;

        @(posedge clk);

        check_output(
            SONG_0,
            BPM_SONG_0,
            "READY SONG 0"
        );


        // =====================================================
        // TEST 5 : READY SONG 1
        // SONG 1 = 100 BPM
        // =====================================================

        @(negedge clk);

        i_pc_song = SONG_1;

        @(posedge clk);

        check_output(
            SONG_1,
            BPM_SONG_1,
            "READY SONG 1"
        );


        // =====================================================
        // TEST 6 : READY SONG 2
        // SONG 2 = 120 BPM
        // =====================================================

        @(negedge clk);

        i_pc_song = SONG_2;

        @(posedge clk);

        check_output(
            SONG_2,
            BPM_SONG_2,
            "READY SONG 2"
        );


        // =====================================================
        // TEST 7 : READY SONG 3
        // SONG 3 = 140 BPM
        // =====================================================

        @(negedge clk);

        i_pc_song = SONG_3;

        @(posedge clk);

        check_output(
            SONG_3,
            BPM_SONG_3,
            "READY SONG 3"
        );


        // =====================================================
        // TEST 8 : READY SONG 4
        // SONG 4 = 160 BPM
        // =====================================================

        @(negedge clk);

        i_pc_song = SONG_4;

        @(posedge clk);

        check_output(
            SONG_4,
            BPM_SONG_4,
            "READY SONG 4"
        );


        // =====================================================
        // TEST 9 : GAME_ING HOLD
        //
        // READY에서 SONG 4 선택 완료
        // GAME_ING으로 넘어간 뒤 input_song을 SONG 1로 변경
        // 출력은 SONG 4 / 160 BPM 유지되어야 함
        // =====================================================

        @(negedge clk);

        i_pc_state = PC_GAME_ING;
        i_pc_song  = SONG_1;

        @(posedge clk);

        check_output(
            SONG_4,
            BPM_SONG_4,
            "GAME_ING HOLD"
        );


        // =====================================================
        // TEST 10 : GAME_ING INPUT CHANGE HOLD
        //
        // GAME_ING에서 input_song을 다시 변경해도
        // 기존 SONG 4 / 160 BPM 유지
        // =====================================================

        @(negedge clk);

        i_pc_song = SONG_2;

        @(posedge clk);

        check_output(
            SONG_4,
            BPM_SONG_4,
            "GAME_ING INPUT CHANGE HOLD"
        );


        // =====================================================
        // TEST 11 : PC_STOP HOLD
        //
        // STOP 상태에서도 기존 곡 유지
        // =====================================================

        @(negedge clk);

        i_pc_state = PC_STOP;
        i_pc_song  = SONG_3;

        @(posedge clk);

        check_output(
            SONG_4,
            BPM_SONG_4,
            "PC_STOP HOLD"
        );


        // =====================================================
        // TEST 12 : READY 재진입
        //
        // 다시 PC_READY로 들어와 SONG 2 선택
        // 120 BPM으로 변경되어야 함
        // =====================================================

        @(negedge clk);

        i_pc_state = PC_READY;
        i_pc_song  = SONG_2;

        @(posedge clk);

        check_output(
            SONG_2,
            BPM_SONG_2,
            "RESELECT SONG 2"
        );


        // =====================================================
        // TEST 13 : INVALID SONG
        //
        // 현재 RTL 구조:
        //
        // o_song_num <= i_pc_song;
        //
        // default:
        //     o_song_bpm <= 8'd0;
        //
        // 따라서:
        // SONG NUM = 5
        // BPM      = 0
        // =====================================================

        @(negedge clk);

        i_pc_song = 3'b101;

        @(posedge clk);

        check_output(
            3'b101,
            8'd0,
            "INVALID SONG DEFAULT"
        );


        // =====================================================
        // TEST 14 : FINAL ASYNC RESET
        //
        // clk edge와 관계없는 시점에 reset 발생
        // 즉시 출력 0 확인
        // =====================================================

        #2;
        rst = 1'b1;

        check_output(
            3'b000,
            8'd0,
            "FINAL ASYNC RESET"
        );

        #2;
        rst = 1'b0;


        // =====================================================
        // TEST RESULT
        // =====================================================

        #10;

        $display("");
        $display("========================================");
        $display("       SONG DECODER TEST RESULT");
        $display("========================================");
        $display(" PASS : %0d", pass_count);
        $display(" FAIL : %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display(" ALL TESTS PASSED");
        end
        else begin
            $display(" TEST FAILED : %0d CASE(S)", fail_count);
        end

        $display("========================================");
        $display("");

        #10;

        $finish;

    end

endmodule