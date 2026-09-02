`timescale 1ns / 1ps

module sync_fifo #(
    parameter DEPTH = 4,
    parameter AW = $clog2(DEPTH),
    parameter BW = 8
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          we,
    input  logic          re,
    input  logic [BW-1:0] wdata,
    output logic [BW-1:0] rdata,
    output logic          full,
    output logic          empty
);

    logic [AW-1:0] waddr, raddr;
    // regfile
    logic [BW-1:0] mem[0:DEPTH-1];
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= 0;
            end
        end else begin
            if (we) begin
                mem[waddr] <= wdata;
            end
        end
    end
    assign rdata = mem[raddr];


    // addr ctrl unit
    logic [AW-1:0] waddr_next;
    logic [AW-1:0] raddr_next;
    logic full_next, empty_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            waddr <= 0;
            raddr <= 0;
            full  <= 1'b0;
            empty <= 1'b1;
        end else begin
            waddr <= waddr_next;
            raddr <= raddr_next;
            full  <= full_next;
            empty <= empty_next;
        end
    end

    always @(*) begin
        waddr_next = waddr;
        raddr_next = raddr;
        full_next  = full;
        empty_next = empty;
        case ({
            we, re
        })
            // 2'b00: initial at F/F reset
            2'b10: begin
                // push only
                if (!full) begin
                    waddr_next = waddr + 1;
                    empty_next = 1'b0;
                    if (waddr_next == raddr) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b01: begin
                // pop only
                if (!empty) begin
                    raddr_next = raddr + 1;
                    full_next  = 1'b0;
                    if (raddr_next == waddr) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                // push, pop same time
                if (full) begin
                    // if full -> only pop
                    raddr_next = raddr + 1;
                    full_next  = 1'b0;
                end else if (empty) begin
                    // if empty -> only pop 
                    waddr_next = waddr + 1;
                    empty_next = 1'b0;
                end else begin
                    waddr_next = waddr + 1;
                    raddr_next = raddr + 1;
                end
            end
        endcase

    end

endmodule
