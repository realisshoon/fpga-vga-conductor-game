module tb_game_score ();


    logic clk;
    logic rst;
    logic i_score_en;
    logic i_pattern_tick;
    logic [7:0] i_speed;
    logic [7:0] i_song_speed;
    logic score_control_ready;
    logic score_control_valid;
    logic [3:0] o_score;




    game_score U_GAME_SCORE (.*);

    always #5 clk = ~clk;

    task send_speed(input [7:0] speed);
    begin

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);


        i_speed        <= speed;
        i_pattern_tick <= 1'b1;

        @(posedge clk);

        i_pattern_tick <= 1'b0;

    end
    endtask

    initial begin
        clk                 = 0;
        rst                 = 1;

        i_score_en          = 0;
        i_pattern_tick      = 0;
        i_speed             = 0;

        i_song_speed        = 8'd100;

        score_control_ready = 1;
        #20;
        rst = 0;
        @(posedge clk);
        @(posedge clk);

        i_score_en = 1;

        @(posedge clk);
        send_speed(8'd106);
        send_speed(8'd110);
        wait(score_control_valid == 1'b1);


        if (o_score == 4'd6)
            $display("TEST 1 PASS");
        else
            $display("TEST 1 FAIL");

        // valid가 내려갈 때까지 기다림
        wait(score_control_valid == 1'b0);

        // TEST 2
        
        send_speed(8'd130);
        send_speed(8'd130);
        send_speed(8'd130);
        send_speed(8'd130);


        wait(score_control_valid == 1'b1);

        if (o_score == 4'd5)
            $display("TEST 2 PASS");
        else
            $display("TEST 2 FAIL");


        wait(score_control_valid == 1'b0);
        
    //TEST 3
        send_speed(8'd96);
        send_speed(8'd100);
        send_speed(8'd104);
        send_speed(8'd100);
        wait(score_control_valid == 1'b1);


        if (o_score == 4'd6)
            $display("TEST 3 PASS");
        else
            $display("TEST 3 FAIL");

            //end

                    wait(score_control_valid == 1'b0);

        i_score_en = 0;

        #50;
        end

endmodule


// speed를 줄 때 