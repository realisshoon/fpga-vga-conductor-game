module game_score (
    input logic clk,
    input logic rst,
    input logic i_score_en,
    input logic i_pattern_tick,
    input logic i_speed,
    // input logic [2:0] i_song_num,
    input logic [9:0] i_song_speed,
    input logic score_control_ready,
    output logic score_control_valid,
    output logic [7:0] o_score
);

    typedef enum logic [2:0] {
        IDLE  = 3'b000,
        START,
        READY,
        STOP
    } score_state_e;
    score_state_e c_state, n_state;

    logic [7:0] score, score_reg;
    logic [1:0] tick_cnt;

    logic [9:0] score_ram[8];

    //output CL
    assign o_score = score;


    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            score <= 100;
            score_control_valid <= 1'b0;
            tick_cnt <= 0;

        end else begin
            if (i_pattern_tick) begin
                tick_cnt <= tick_cnt + 1'b1;
                score_ram[tick_cnt]<= i_speed;
                score_control_valid<= 1'b1;

            end else if(tick_cnt == 3) begin
                tick_cnt <= 0;
            end  
        else if (score_control_valid && score_control_ready) begin
                score_control_valid <= 1'b0;
            end else begin
                c_state <= n_state;
                score   <= score_reg;
                score_control_valid <= 1'b0;
            end
        end
    end






    //Next CL 
    always_comb begin
        n_state   = c_state;
        score_reg = score;
        case (c_state)
            IDLE: begin
                if (i_score_en) begin
                    n_state = START;
                end
            end

            STOP: begin
                //현재 점수 출력
                n_state = IDLE;

            end

        endcase

    end




endmodule
