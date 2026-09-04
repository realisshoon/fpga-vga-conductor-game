`timescale 1ns / 1ps

module vga_decoder (
    input  logic       clk,
    input  logic       rst,
    output logic       xclk,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       de
);

    wire w_pclk;
    wire [9:0] h_cnt;
    wire [9:0] v_cnt;

    assign xclk = w_pclk;

    pclk_gen U_PCLK_GEN (
        .clk (clk),
        .rst (rst),
        .pclk(w_pclk)
    );

    pixel_counter U_PIXEL_COUNTER (
        .clk  (clk),
        .rst  (rst),
        .pclk (w_pclk),
        .h_cnt(h_cnt),   // 0~799
        .v_cnt(v_cnt)    // 0~524
    );

    sync_block U_SYNC_BLOCK (
        .h_cnt  (h_cnt),
        .v_cnt  (v_cnt),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de     (de)
    );

endmodule

module pclk_gen (
    input      clk,
    input      rst,
    output reg pclk
);
    reg [1:0] p_cnt;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            p_cnt <= 0;
            pclk  <= 0;
        end else begin
            if (p_cnt == 2'd3) begin
                p_cnt <= 0;
                pclk  <= 1;
            end else begin
                p_cnt <= p_cnt + 1;
                pclk  <= 0;
            end
        end
    end

endmodule

module pixel_counter (
    input            clk,
    input            rst,
    input            pclk,
    output reg [9:0] h_cnt,  // 0~799
    output reg [9:0] v_cnt   // 0~524
);
    localparam H_MAX = 800, V_MAX = 525;
    // h_cnt
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            h_cnt <= 0;
        end else begin
            if (pclk) begin
                if (h_cnt == H_MAX - 1) begin
                    h_cnt <= 0;
                end else begin
                    h_cnt <= h_cnt + 1;
                end
            end
        end
    end
    // v_cnt
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            v_cnt <= 0;
        end else begin
            if (pclk) begin
                if (h_cnt == H_MAX - 1) begin
                    if (v_cnt == V_MAX - 1) begin
                        v_cnt <= 0;
                    end else begin
                        v_cnt <= v_cnt + 1;
                    end
                end
            end
        end
    end

endmodule

module sync_block (
    input  [9:0] h_cnt,
    input  [9:0] v_cnt,
    output       h_sync,
    output       v_sync,
    output [9:0] x_pixel,
    output [9:0] y_pixel,
    output       de
);
    // Horizontal spec.
    localparam H_Visible_area = 640;
    localparam H_Front_porch  = 16;
    localparam H_Sync_pulse   = 96;
    localparam H_Back_porch   = 48;
    localparam H_Whole_line   = 800;
    // Vertical spec.
    localparam V_Visible_area = 480;
    localparam V_Front_porch  = 10;
    localparam V_Sync_pulse   = 2;
    localparam V_Back_porch   = 33;
    localparam V_Whole_frame  = 525;

    assign x_pixel = h_cnt;
    assign y_pixel = v_cnt;

    assign h_sync = !((h_cnt >= (H_Visible_area + H_Front_porch)) && (h_cnt < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_cnt >= (V_Visible_area + V_Front_porch)) && (v_cnt < (V_Visible_area + V_Front_porch + V_Sync_pulse)));

    assign de = (h_cnt < H_Visible_area) && (v_cnt < V_Visible_area);

endmodule
