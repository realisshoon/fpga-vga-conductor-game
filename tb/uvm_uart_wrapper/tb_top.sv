`timescale 1ns / 1ps

import uvm_pkg::*;
import uart_wrapper_pkg::*;

module tb_top;
    logic clk;
    logic rst;
    logic pixel_dec_sync;

    localparam int CLK_FREQ_HZ = 100_000_000;
    localparam int FRAME_HZ = 30_0; // for fast test
    localparam int FRAME_CYCLES = CLK_FREQ_HZ / FRAME_HZ;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        forever begin
        pixel_dec_sync <= 1'b0;
        repeat(FRAME_CYCLES-1) @(posedge clk);
        pixel_dec_sync <= 1'b1;
        @(posedge clk);
        end
    end

    uart_wrapper_interface vif (
        .clk           (clk),
        .rst           (rst),
        .pixel_dec_sync(pixel_dec_sync)
    );

    uart_wrapper dut (
        .clk                  (clk),
        .rst                  (rst),
        .pixel_dec_sync       (pixel_dec_sync),
        .volume_uart_ready    (vif.volume_uart_ready),
        .i_volume_level       (vif.i_volume_level),
        .volume_uart_valid    (vif.volume_uart_valid),
        .xy_uart_ready        (vif.xy_uart_ready),
        .i_pixel              (vif.i_pixel),
        .xy_uart_valid        (vif.xy_uart_valid),
        .stick_control_ready  (vif.stick_control_ready),
        .i_speed              (vif.i_speed),
        .stick_control_valid  (vif.stick_control_valid),
        .score_control_ready  (vif.score_control_ready),
        .i_score              (vif.i_score),
        .score_control_valid  (vif.score_control_valid),
        .game_control_ready   (vif.game_control_ready),
        .i_game_state         (vif.i_game_state),
        .game_control_valid   (vif.game_control_valid),
        .pattern_control_ready(vif.pattern_control_ready),
        .pattern_control_valid(vif.pattern_control_valid),
        .i_pattern_state      (vif.i_pattern_state),
        .o_rx_data            (vif.o_rx_data),
        .tx                   (vif.tx),
        .rx                   (vif.rx)
    );

    assign vif.rx_done = dut.U_UART.done;

    initial begin
        rst = 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
    end

    initial begin
        uvm_config_db#(virtual uart_wrapper_interface)::set(null, "*", "vif",
                                                            vif);
        run_test();
    end

    initial begin
        $fsdbDumpfile("uart_wrapper_tb.fsdb");
        $fsdbDumpvars(0, tb_top);
    end
endmodule
