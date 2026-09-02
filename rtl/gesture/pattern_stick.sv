`timescale 1ns / 1ps


module pattern_stick (
    input  logic       clk,
    input  logic       rst,
    input  logic       game_start,
    input  logic       game_stop,
    input  logic [9:0] i_stick_x_pixel,
    input  logic [9:0] i_stick_y_pixel,
    input  logic       i_vsync,
    input  logic       pattern_control_ready,
    output logic       pattern_control_valid,
    output logic [2:0] pattern_state,
    output logic       pattern_tick
);

    logic pattern_tick_reg;
    logic zone1, zone2, zone3, zone4;

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
    pattern_state_e c_state, n_state;

    assign zone1 = (i_stick_x_pixel >= 140 && i_stick_x_pixel <= 180) && (i_stick_y_pixel >= 175 && i_stick_y_pixel <= 240);
    assign zone2 = (i_stick_x_pixel >= 75 && i_stick_x_pixel <= 125) && (i_stick_y_pixel >= 110 && i_stick_y_pixel <= 160);
    assign zone3 = (i_stick_x_pixel >= 195 && i_stick_x_pixel <= 245) && (i_stick_y_pixel >= 110 && i_stick_y_pixel <= 160);
    assign zone4 = (i_stick_x_pixel >= 140 && i_stick_x_pixel <= 180) && (i_stick_y_pixel >= 0 && i_stick_y_pixel <= 60);

    assign pattern_state = c_state;

    // State/output registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state               <= IDLE;
            pattern_tick          <= 1'b0;
            pattern_control_valid <= 1'b0;
        end else begin
            pattern_tick <= 1'b0;

            if (i_vsync) begin
                pattern_control_valid <= 1'b0;
            end else if (pattern_control_valid) begin
                if (pattern_control_ready) pattern_control_valid <= 1'b0;
            end else if (n_state != c_state) begin
                c_state               <= n_state;
                pattern_tick          <= pattern_tick_reg;
                pattern_control_valid <= 1'b1;
            end
        end
    end
    //Next CL
    always_comb begin
        n_state = c_state;
        pattern_tick_reg = 1'b0;
        case (c_state)
            IDLE: begin
                if (game_start) begin
                    n_state = START;
                    pattern_tick_reg = 1'b1;
                end
            end
            START: begin
                if (!zone4) begin
                    n_state = READY;
                end
            end
            READY : begin
                if (zone1) begin
                    n_state = PATTERN_1;
                    pattern_tick_reg = 1'b1;
                end
            end
            PATTERN_1: begin
                if (game_stop) begin
                    n_state = STOP;
                    pattern_tick_reg = 1'b1;

                end else if (zone2) begin
                    n_state = PATTERN_2;
                    pattern_tick_reg = 1'b1;
                end
            end
            PATTERN_2: begin
                if (game_stop) begin
                    n_state = STOP;
                    pattern_tick_reg = 1'b1;

                end else if (zone3) begin
                    n_state = PATTERN_3;
                    pattern_tick_reg = 1'b1;
                end
            end
            PATTERN_3: begin
                if (game_stop) begin
                    n_state = STOP;
                    pattern_tick_reg = 1'b1;

                end else if (zone4) begin
                    n_state = PATTERN_4;
                    pattern_tick_reg = 1'b1;
                end
            end
            PATTERN_4: begin
                if (game_stop) begin
                    n_state = STOP;
                    pattern_tick_reg = 1'b1;

                end else if (zone1) begin
                    n_state = PATTERN_1;
                    pattern_tick_reg = 1'b1;
                end
            end
            STOP: begin
                n_state = IDLE;
            end
        endcase
    end

    //output CL



endmodule
