module game_score  (
    input logic clk,
    input logic rst,
    input logic i_score_en,
    input logic i_pattern_tick,
    input logic [7:0] i_speed,
    // input logic [2:0] i_song_num,
    input logic [7:0] i_song_speed,
    input logic score_control_ready,
    output logic score_control_valid,
    output logic [3:0] o_score
);

    typedef enum logic [2:0] {
        IDLE = 2'b00,
        COLLECT,
        CALC,
        SEND
    } score_state_e;
    score_state_e c_state, n_state;

    logic [3:0] score;
    logic [1:0] tick_cnt;

    logic [7:0] speed_ram [4];

    logic [9:0] speed_sum;
    logic [9:0] avg_speed, speed_diff;



    // 평균 속도 / 차이 계산
    always_comb begin

        speed_sum =
              {2'b00, speed_ram[0]}
            + {2'b00, speed_ram[1]}
            + {2'b00, speed_ram[2]}
            + {2'b00, speed_ram[3]};

        // 4개 평균
        avg_speed = speed_sum >> 2;


        // 절대값 차이
        if (avg_speed >= i_song_speed) speed_diff = avg_speed - i_song_speed;
        else speed_diff = i_song_speed - avg_speed;

    end



    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= IDLE;

        end else begin
            c_state <= n_state;

        end
    end

    //Next state CL 
    always_comb begin
        n_state = c_state;
        case (c_state)
            IDLE: begin
                if (i_score_en) begin
                    n_state = COLLECT;
                end
            end
            COLLECT: begin
                if (!i_score_en) begin
                    n_state = IDLE;
                end else if (i_pattern_tick && (tick_cnt == 3)) begin
                    n_state = CALC;
                end
            end
            CALC: begin
                if (!i_score_en) begin
                    n_state = IDLE;
                end else n_state = SEND;
            end
            SEND: begin
                if (!i_score_en) begin
                    n_state = IDLE;
                end else if (score_control_ready) begin  //핸드셰이크
                    n_state = COLLECT;
                end
            end

        endcase

    end
    //output CL
    always_comb begin
        o_score = score;
        score_control_valid = 1'b0;
        case (c_state)
            IDLE: begin
                score_control_valid = 1'b0;
            end
            COLLECT: begin
                score_control_valid = 1'b0;
            end
            CALC: begin
                score_control_valid = 1'b0;
            end
            SEND: begin
                score_control_valid = 1'b1;
            end
        endcase
    end



    //Data Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt <= 2'd2;
            speed_ram[0] <= 8'd100;
            speed_ram[1] <= 8'd100;
            speed_ram[2] <= 8'd100;
            speed_ram[3] <= 8'd100;
            score <= 8'd5;

        end else begin
            case (c_state)
                IDLE: begin
                    tick_cnt <= 2'd2;
                    speed_ram[0] <= i_song_speed;
                    speed_ram[1] <= i_song_speed;
                    speed_ram[2] <= i_song_speed;
                    speed_ram[3] <= i_song_speed;
                    score <= 8'd5;

                end
                COLLECT: begin
                    if (i_score_en && i_pattern_tick) begin
                        speed_ram[tick_cnt] <= i_speed;
                        tick_cnt <= tick_cnt + 1;
                    end
                end
                CALC: begin
                    if (i_score_en) begin
                        if (speed_diff > 20) begin
                            if (score == 4'b0) begin
                                score <= score;
                            end else begin
                                score <= score - 1;
                            end
                        end else if(speed_diff < 10) begin
                            if (score == 4'd10) begin
                            score <= score;
                        end else begin
                            score <= score + 1;
                        end
                        end
                    end
                end
                SEND: begin
                    score <= score;
                end

            endcase
        end
    end


endmodule
