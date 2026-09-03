`timescale 1ns / 1ps

module stick_speed_calc  #(
    parameter CLK_FREQ = 100_000_000,
    parameter MIN_BPM  = 30,
    parameter MAX_BPM  = 220
) (

    input logic       clk,
    input logic       rst,
    input logic       i_vsync,
    input logic       i_pattern_tick,
    input logic [2:0] i_pattern_state,
    input logic       stick_control_ready,
    input logic [7:0] i_pc_song_bpm,

    output logic       stick_control_valid,
    output logic       o_pattern_tick,
    output logic       o_state_change_enable,
    output logic [7:0] o_speed
);

    // Conduct state
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        READY,
        PATTERN_1,
        PATTERN_2,
        PATTERN_3,
        PATTERN_4,
        STOP
    } pattern_state_e;

    // Speed FSM
    typedef enum logic [2:0] {
        S_IDLE,
        S_READY,
        S_COUNT,
        S_FAST,
        S_NORMAL
    } speed_state_e;

    speed_state_e c_state, n_state;

    // 현재 지휘 시간
    logic [27:0] count_reg;

    // 현재 재생 중인 노래
    logic [7:0] song_bpm;
    logic [27:0] song_cnt;

    // 방금 측정한 지휘 결과
    logic [7:0] stick_bpm;
    logic [27:0] stick_cnt;

    // FAST 대기 시간
    logic [27:0] time_count;

    // BPM 계산
    logic [63:0] bpm_calc;
    logic [7:0] bpm_idx;

    // 5 BPM LUT
    logic [7:0] arr[0:255];

    integer i;

    // LUT : 30 ~ 220 BPM, 5 BPM 단위
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            if (i < MIN_BPM) arr[i] = MIN_BPM;
            else if (i > MAX_BPM) arr[i] = MAX_BPM;
            else arr[i] = ((i + 2) / 5) * 5;
        end
    end

    // 현재 count → BPM
    always_comb begin
        bpm_calc = (64'd60 * CLK_FREQ) / (count_reg + 28'd1);
        if (bpm_calc < MIN_BPM) bpm_idx = MIN_BPM;
        else if (bpm_calc > MAX_BPM) bpm_idx = MAX_BPM;
        else bpm_idx = bpm_calc[7:0];
    end

    // Next State Logic
    always_comb begin
        n_state = c_state;
        // STOP은 최우선
        if ((i_pattern_state == STOP)||(i_pattern_state == IDLE) || (i_pattern_state == START)) begin
            n_state = S_IDLE;
        end else begin
            case (c_state)
                S_IDLE: begin
                    if (i_pattern_state == READY) n_state = S_READY;
                end
                S_READY: begin
                    if (i_pattern_tick) n_state = S_COUNT;
                end
                S_COUNT: begin
                    if (i_pattern_tick) begin
                        // BPM이 클수록 빠른 지휘
                        if (arr[bpm_idx] > song_bpm) n_state = S_FAST;
                        else n_state = S_NORMAL;
                    end
                end
                S_FAST: begin
                    // 남아있는 이전 음악 시간만 기다림
                    if (time_count + 28'd1 >= song_cnt - stick_cnt)
                        n_state = S_COUNT;
                end
                S_NORMAL: begin
                    // 출력용 1 clk 상태
                    n_state = S_COUNT;
                end
                default: begin
                    n_state = S_IDLE;
                end
            endcase
        end
    end

    // State Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state             <= S_IDLE;
            count_reg           <= 28'd0;
            time_count          <= 28'd0;
            song_bpm            <= i_pc_song_bpm;
            song_cnt            <= (64'd60 * CLK_FREQ) / i_pc_song_bpm;
            stick_bpm           <= i_pc_song_bpm;
            stick_cnt           <= 28'd0;
            o_speed             <= i_pc_song_bpm;
            stick_control_valid <= 1'b0;
            o_pattern_tick      <= 1'b0;
        end else begin
            c_state <= n_state;
            // pattern tick 출력은 기본 0
            o_pattern_tick <= 1'b0;
            // valid / ready handshake
            if (stick_control_valid && stick_control_ready)
                stick_control_valid <= 1'b0;
            case (c_state)
                // IDLE
                S_IDLE: begin
                    count_reg  <= 28'd0;
                    time_count <= 28'd0;
                end
                // READY
                // 첫 시작은 정박자
                S_READY: begin

                    song_bpm            <= i_pc_song_bpm;
                    song_cnt            <= (64'd60 * CLK_FREQ) / i_pc_song_bpm;
                    o_speed             <= i_pc_song_bpm;
                    stick_control_valid <= 1'b1;
                    count_reg           <= 28'd0;
                    if (i_pattern_tick) begin
                        o_pattern_tick <= 1'b1;
                    end
                end
                // COUNT
                // 현재 지휘 시간 측정
                S_COUNT: begin
                    if (i_pattern_tick) begin
                        // 현재 지휘 결과 저장
                        stick_cnt  <= count_reg + 28'd1;
                        stick_bpm  <= arr[bpm_idx];
                        // 다음 동작 준비
                        count_reg  <= 28'd0;
                        time_count <= 28'd0;
                    end else begin
                        // overflow 방지
                        if (count_reg != 28'hFFF_FFFF)
                            count_reg <= count_reg + 28'd1;
                    end
                end
                // FAST
                // 이전 음악이 끝날 때까지 대기
                S_FAST: begin
                    // 지휘 count는 하지 않음
                    count_reg <= 28'd0;

                    // FAST 진입 첫 clk에만 출력
                    if (time_count == 0) begin
                        o_speed             <= stick_bpm;
                        stick_control_valid <= 1'b1;
                        o_pattern_tick      <= 1'b1;
                    end
                    if (n_state == S_COUNT) begin
                        // 다음 음악 기준값 갱신
                        song_bpm   <= stick_bpm;
                        song_cnt   <= (64'd60 * CLK_FREQ) / stick_bpm;
                        time_count <= 28'd0;
                    end else begin
                        time_count <= time_count + 28'd1;
                    end
                end
                // NORMAL
                // 다음 clk에 바로 COUNT
                S_NORMAL: begin
                    // 다음 음악 기준값 갱신
                    o_speed             <= stick_bpm;
                    stick_control_valid <= 1'b1;
                    o_pattern_tick      <= 1'b1;
                    song_bpm            <= stick_bpm;
                    song_cnt            <= (64'd60 * CLK_FREQ) / stick_bpm;
                    count_reg           <= 28'd0;
                end
            endcase
            // VSYNC → valid clear
            if (i_vsync) stick_control_valid <= 1'b0;
        end
    end

    // State Change Enable
    always_comb begin
        case (c_state)
            S_FAST, S_NORMAL: o_state_change_enable = 1'b0;
            default: o_state_change_enable = 1'b1;
        endcase
    end
endmodule
