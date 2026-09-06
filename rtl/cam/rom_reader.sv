`timescale 1ns / 1ps

module rom_reader (
    input  logic        clk,
    input  logic        rst,
    input  logic        de,
    input  logic        sw_invert,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic [16:0] addr,
    input  logic [15:0] px_data,
    output logic [11:0] o_rgb
);
    logic [11:0] px_data_rgb;
    assign px_data_rgb = {px_data[15:12], px_data[10:7], px_data[4:1]};

    // QVGA
    logic dispArea, dispArea_d;
    assign dispArea = de && (x_pixel < 320) && (y_pixel < 240);
    assign addr = (dispArea) ? (y_pixel * 320 + (319 - x_pixel)) : 0;
    assign o_rgb = (dispArea_d) ? px_data_rgb : {12{(sw_invert)}};

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dispArea_d <= 1'b0;
        end else begin
            dispArea_d <= dispArea;
        end
    end

    // // VGA
    // logic de_d;
    // assign addr = (de_d) ? (y_pixel[9:1] * 320 + x_pixel[9:1]) : 0;
    // assign o_rgb = (de_d) ? px_data_rgb : 0;
    // 
    // always @(posedge clk, posedge reset) begin
    //     if (reset) begin
    //         de_d <= 1'b0;
    //     end else begin
    //         de_d <= de;
    //     end
    // end
endmodule
