`timescale 1ns / 1ps

module frame_buffer #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 16,
    parameter AW = $clog2(IMG_H * IMG_W)
) (
    // write side(camera, pclk)
    input  logic          wclk,
    input  logic          we,
    input  logic [AW-1:0] wAddr,
    input  logic [DW-1:0] wData,
    // read side(VGA, clk)
    input  logic          rclk,
    input  logic [AW-1:0] rAddr,
    output logic [DW-1:0] rData
);
    logic [DW-1:0] mem[0:IMG_W*IMG_H- 1];

    // write
    always @(posedge wclk) begin
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    // read
    always @(posedge rclk) begin
        rData <= mem[rAddr];
    end
endmodule
