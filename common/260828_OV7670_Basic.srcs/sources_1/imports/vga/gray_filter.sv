`timescale 1ns / 1ps

// module gray_filter (
//     input  logic [11:0] i_rgb,
//     output logic [11:0] o_rgb
// );
//     logic [11:0] y;
// 
//     assign y = 77 * i_rgb[11:8] + 150 * i_rgb[7:4] + 29 * i_rgb[3:0];
//     assign o_rgb = {y[11:8], y[11:8], y[11:8]};
// 
// endmodule

module gray_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic        sw_gray,
    input  logic        i_h_sync,
    input  logic        i_v_sync,
    input  logic [11:0] i_rgb,
    output logic        o_h_sync,
    output logic        o_v_sync,
    output logic [11:0] o_rgb
);
    localparam LATENCY = 2;

    // ------------------------ Stage 1 : Multipying ----------------------------
    logic [11:0] s1_r, s1_g, s1_b, s1_rgb;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            s1_r   <= 0;
            s1_g   <= 0;
            s1_b   <= 0;
            s1_rgb <= 0;
        end else begin
            s1_r   <= 8'd77 * i_rgb[11:8];
            s1_g   <= 8'd150 * i_rgb[7:4];
            s1_b   <= 8'd29 * i_rgb[3:0];
            s1_rgb <= i_rgb;
        end
    end
    // ------------------------ Stage 2 : Add, Shift, MUX ----------------------------
    logic [11:0] sum;
    logic [ 3:0] gray;
    assign sum  = s1_r + s1_g + s1_b;
    assign gray = sum[11:8];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_rgb <= 0;
        end else begin
            o_rgb <= (sw_gray) ? {gray, gray, gray} : s1_rgb;
        end
    end
    // ------------------------ sync signals --------------------------
    logic [LATENCY - 1 : 0] h_sync_d, v_sync_d;
    assign o_h_sync = h_sync_d[LATENCY-1];
    assign o_v_sync = v_sync_d[LATENCY-1];
    // shift register, LSB to MSB
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            h_sync_d <= 1;
            v_sync_d <= 1;
        end else begin
            h_sync_d <= {h_sync_d[0:0], i_h_sync};
            v_sync_d <= {v_sync_d[0:0], i_v_sync};
        end
    end
endmodule
