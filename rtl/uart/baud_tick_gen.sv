`timescale 1ns / 1ps

module baud_tick_gen #(
    parameter BAUD_RATE = 115_200,
    parameter SAMPLE = 16
) (
    input  logic clk,
    input  logic rst,
    input logic busy,
    output logic baud_tick,
    output logic sampling_tick
);

    localparam SYS_RATE = 100_000_000;  // 100MHz system clock
    localparam SAMPLE_RATE = SYS_RATE / BAUD_RATE / SAMPLE;

    // tick generator
    logic [$clog2(SAMPLE)-1:0] cnt_sampling_tick;
    logic [$clog2(SAMPLE_RATE)-1:0] cnt;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt_sampling_tick <= 0;
            cnt               <= 0;
            baud_tick         <= 1'b0;
            sampling_tick     <= 1'b0;
        end else begin
            if (cnt == SAMPLE_RATE - 1) begin
                cnt           <= 0;
                sampling_tick <= 1'b1;
            end else begin
                cnt <= cnt + 1;
                sampling_tick <= 1'b0;
            end
            if (sampling_tick && busy) begin
                if (cnt_sampling_tick == SAMPLE - 1) begin
                    cnt_sampling_tick <= 0;
                    baud_tick     <= 1'b1;
                end else begin
                    cnt_sampling_tick <= cnt_sampling_tick + 1;
                    baud_tick         <= 1'b0;
                end
            end else baud_tick <= 1'b0;
        end
    end

endmodule
