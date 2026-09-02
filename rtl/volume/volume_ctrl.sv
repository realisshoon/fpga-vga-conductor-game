`timescale 1ns / 1ps

module volume_ctrl #(
    parameter integer INITIAL_VOLUME = 50,    // 볼륨 초기값
    parameter integer MAX_VOLUME = 100,       // 볼륨 최대값
    parameter integer SCALE = 2,              // 2픽셀 당 1 볼륨 변화량
    parameter integer WAIT_FRAMES = 30,       // 기준 좌표를 잡기 전 대기 프레임 수
    parameter integer TRACK_FRAMES = 10       // 볼륨 계산 주기 프레임 수
) (
    input logic clk,
    input logic rst,
    // xy_detection
    input logic i_vsync,                      // 새로운 프레임 좌표가 갱신됨.
    input logic [9:0] i_hand_y_pixel,         // 현재 손의 y 좌표
    // tx_data control interface                    
    input  logic       volume_control_ready,  // tx_data 제어 모듈이 볼륨 데이터를 받을 수 있음.
    output logic       volume_control_valid,  // 새로운 볼륨 데이터가 준비됨.
    output logic [6:0] o_volume_level         // 계산된 볼륨 0 ~ 100
);

    localparam logic [9:0] NO_HAND = 10'h3FF;

    // 프레임 수가 바뀌면 카운터 비트 수도 자동으로 변경된다.
    // $clog2(1)은 0이므로, 최소 비트 수는 1비트로 제한한다.
    localparam integer WAIT_COUNT_WIDTH =
        (WAIT_FRAMES > 1) ? $clog2(WAIT_FRAMES) : 1;
    localparam integer TRACK_COUNT_WIDTH =
        (TRACK_FRAMES > 1) ? $clog2(TRACK_FRAMES) : 1;

    logic [WAIT_COUNT_WIDTH-1:0] wait_count_c, wait_count_n;
    logic [TRACK_COUNT_WIDTH-1:0] track_count_c, track_count_n;
    logic [9:0] base_y_c, base_y_n;            // 기준 Y좌표
    logic [6:0] volume_c, volume_n;            // 현재/다음 볼륨 0~100
    logic       valid_c, valid_n;              // 현재/다음 valid
    logic [6:0] volume_data_c, volume_data_n;  // handshake 출력 데이터

    logic signed [10:0] delta_y;               // base_y_c - 현재 Y좌표
    logic signed [10:0] volume_change;         // delta_y / SCALE
    logic signed [12:0] volume_sum;            // Clamp 전 누적 볼륨
    logic        [6:0]  volume_clamped;        // 0~100 Clamp 결과

    typedef enum logic [1:0] {
        S_IDLE,
        S_WAIT,
        S_TRACK
    } state_t;

    state_t c_state;         // 현재 상태
    state_t n_state;         // 다음 상태
    
    assign volume_control_valid = valid_c;
    assign o_volume_level       = volume_data_c;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= S_IDLE;
            wait_count_c   <= '0;
            track_count_c  <= '0;
            base_y_c       <= 10'd0;
            volume_c       <= INITIAL_VOLUME;
            valid_c        <= 1'b0;
            volume_data_c  <= INITIAL_VOLUME;
        end else begin
            c_state        <= n_state;
            wait_count_c   <= wait_count_n;
            track_count_c  <= track_count_n;
            base_y_c       <= base_y_n;
            volume_c       <= volume_n;
            valid_c        <= valid_n;
            volume_data_c  <= volume_data_n;
        end
    end

    always_comb begin
        // 모든 레지스터의 기본값은 현재 값 유지이다.
        n_state         = c_state;
        wait_count_n    = wait_count_c;
        track_count_n   = track_count_c;
        base_y_n        = base_y_c;
        volume_n        = volume_c;
        valid_n         = valid_c;
        volume_data_n   = volume_data_c;

        // signed 좌표 차이와 볼륨 변화량 계산
        delta_y =
            $signed({1'b0, base_y_c})
          - $signed({1'b0, i_hand_y_pixel});

        volume_change = delta_y / SCALE;

        // 두 피연산자를 13비트 signed로 확장한 뒤 더한다.
        volume_sum =
            $signed({6'b0, volume_c})
          + $signed({{2{volume_change[10]}}, volume_change});

        // 누적 결과를 0~100 범위로 Clamp한다.
        if (volume_sum < 0) begin
            volume_clamped = 7'd0;
        end else if (volume_sum > MAX_VOLUME) begin
            volume_clamped = MAX_VOLUME;
        end else begin
            volume_clamped = volume_sum[6:0];
        end

        // 현재 출력 데이터의 handshake가 완료되면 valid를 내린다.
        if (valid_c && volume_control_ready) begin
            valid_n = 1'b0;
        end

        // 새로운 프레임이 들어오면 이전 프레임의 valid를 내린다.
        if (i_vsync) begin
            valid_n = 1'b0;
        end

        case (c_state)
            S_IDLE: begin
                wait_count_n  = '0;
                track_count_n = '0;

                if (i_vsync && (i_hand_y_pixel != NO_HAND)) begin
                    // 상태가 바뀌면 counter는 0부터 시작한다.
                    // 이 프레임은 손 검출 및 WAIT 진입 용도로만 사용한다.
                    wait_count_n = '0;
                    n_state      = S_WAIT;
                end
            end

            S_WAIT: begin
                track_count_n = '0;

                if (i_vsync) begin
                    if (((wait_count_c == TRACK_FRAMES - 1)       ||
                         (wait_count_c == (TRACK_FRAMES * 2) - 1) ||
                         (wait_count_c == WAIT_FRAMES - 1)) &&
                        (i_hand_y_pixel == NO_HAND)) begin

                        wait_count_n = '0;
                        n_state      = S_IDLE;
                    end else if ((wait_count_c == WAIT_FRAMES - 1) &&
                                 (i_hand_y_pixel != NO_HAND)) begin

                        base_y_n       = i_hand_y_pixel;
                        wait_count_n   = '0;
                        track_count_n  = '0;

                        // 기준점을 새로 잡으면 볼륨을 다시 초기값으로 설정한다.
                        volume_n = INITIAL_VOLUME;

                        n_state = S_TRACK;
                    end else begin
                        wait_count_n = wait_count_c + 1'b1;
                    end
                end
            end

            S_TRACK: begin
                wait_count_n = '0;

                if (i_vsync) begin
                    if (track_count_c == TRACK_FRAMES - 1) begin
                        // count=0에서 시작해 10번째 VSYNC가 들어오면
                        // 계산하고 다시 0으로 초기화한다.
                        track_count_n = '0;

                        if (i_hand_y_pixel == NO_HAND) begin
                            n_state = S_IDLE;
                        end else begin
                            // 계산된 볼륨이 실제로 달라졌을 때만
                            // 볼륨과 기준 좌표를 함께 갱신한다.
                            if (volume_clamped != volume_c) begin
                                volume_n = volume_clamped;
                                base_y_n = i_hand_y_pixel;
                            end
                        end
                    end else begin
                        track_count_n = track_count_c + 1'b1;
                    end
                end
            end

            default: begin
                n_state       = S_IDLE;
                wait_count_n  = '0;
                track_count_n = '0;
            end
        endcase

        // 내부 볼륨과 마지막 출력 데이터가 다르면 새 데이터를 출력한다.
        // valid=1, ready=0인 동안에는 기존 data와 valid를 유지한다.
        if (!valid_n && (volume_n != volume_data_n)) begin
            volume_data_n = volume_n;
            valid_n       = 1'b1;
        end
    end

endmodule
