`timescale 1ns / 1ps

module ov7670_mem_controller #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 16,
    parameter AW = $clog2(IMG_H * IMG_W)
) (
    input  logic          reset,
    input  logic          pclk,       // cdc
    input  logic          cam_href,
    input  logic          cam_vsync,  // 30fps
    input  logic [   7:0] cam_data,
    output logic          we,
    output logic [AW-1:0] wAddr,
    output logic [DW-1:0] wData
);
    // logic byteSel;
    // logic [DW-1:0] px_data;
    // 
    // assign wData = px_data;
    // 
    // always @(posedge pclk, posedge reset) begin
    //     if (reset) begin
    //         wAddr   <= 0;
    //         byteSel <= 0;
    //         px_data <= 0;
    //         we      <= 1'b0;
    //     end else begin
    //         we <= 1'b0;
    //         if (we) wAddr <= wAddr + 1;
    //         if (cam_vsync) begin
    //             wAddr   <= 0;
    //             byteSel <= 1'b0;
    //         end else begin  // vsync disable
    //             if (cam_href) begin
    //                 byteSel <= ~byteSel;
    //                 if (!byteSel) begin
    //                     px_data[15:8] <= cam_data;
    //                 end else begin
    //                     px_data[7:0] <= cam_data;
    //                     we <= 1'b1;
    //                 end
    //             end
    //         end
    //     end
    // end



    // data register
    logic none;  // flag of 1st byte 
    always @(posedge pclk, posedge reset) begin
        if (reset) begin
            wData <= 0;
            none <= 0;
            we <= 0;
        end else begin
            if (!cam_vsync) begin
                if (cam_href) begin
                    wData <= {wData[7:0], cam_data};
                    none <= ~none;
                    we <= none;
                end else begin
                    wData[7:0] <= cam_data;
                    none <= 0;
                    we <= 0;
                end
            end else begin
                wData <= 0;
                none <= 0;
                we <= 0;
            end
        end
    end

    // waddr counter
    always @(posedge pclk, posedge reset) begin
        if (reset) begin
            wAddr <= 0;
        end else begin
            if (!cam_vsync) begin
                // writing and addr update simultaneously
                if (we) begin
                    wAddr <= wAddr + 1;
                end
            end else begin
                wAddr <= 0;
            end
        end
    end
endmodule

