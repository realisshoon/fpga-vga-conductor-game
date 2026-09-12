`timescale 1ns / 1ps

module tb_baud_tick_gen ();
    parameter BAUD_RATE = 115_200;
    parameter SAMPLE = 16;
    localparam SYS_RATE = 100_000_000;  // 100MHz system clock
    localparam SAMPLE_RATE = SYS_RATE / BAUD_RATE / SAMPLE;
    logic clk;
    logic rst;
    logic baud_tick;
    logic sampling_tick;

    baud_tick_gen dut (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .sampling_tick(sampling_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        rst = 0;

        repeat(SYS_RATE/BAUD_RATE) @(posedge clk);
        repeat(SYS_RATE/BAUD_RATE) @(posedge clk);

        repeat(100) @(posedge clk);
        $finish;
    end
endmodule
