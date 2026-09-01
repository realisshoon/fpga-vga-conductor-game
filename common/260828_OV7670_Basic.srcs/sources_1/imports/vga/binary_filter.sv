`timescale 1ns / 1ps

module binary_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic        sw_binary,
    input  logic [ 3:0] sw_th,
    input  logic        sw_invert,
    input  logic [11:0] i_rgb,
    input  logic        i_h_sync,
    input  logic        i_v_sync,
    output logic [11:0] o_rgb,
    output logic        o_h_sync,
    output logic        o_v_sync
);
    // sync signals
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_h_sync <= 1;
            o_v_sync <= 1;
        end else begin
            o_h_sync <= i_h_sync;
            o_v_sync <= i_v_sync;
        end
    end

    // filter
    logic [3:0] gray;
    logic [11:0] b_rgb;
    logic over;
    assign gray  = i_rgb[3:0];
    assign over  = (gray >= sw_th) ^ sw_invert;
    assign b_rgb = (over) ? 12'hFFF : 12'h000;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_rgb <= 0;
        end else begin
            o_rgb <= (sw_binary) ? b_rgb : i_rgb;
        end
    end
endmodule
