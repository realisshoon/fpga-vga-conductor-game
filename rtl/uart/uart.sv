`timescale 1ns / 1ps

module uart #(
    parameter BAUD_RATE = 115_200,
    parameter SAMPLE = 16,
    parameter DEPTH = 8,
    parameter BW = 8
) (
    input  logic                clk,
    input  logic                rst,
    // uart interface
    output logic                tx,
    input  logic                rx,
    // inner data signal
    output logic                uart_data_control_uart_ready,
    input  logic                uart_data_control_uart_valid,
    input  logic [DEPTH*BW-1:0] i_tx_data,
    output logic [         7:0] o_rx_data
);
    // handshake signal
    logic                i_tx_data_hs;

    // fifo 
    logic                we;
    logic                re;
    logic [      BW-1:0] wdata;
    logic                full;
    logic                empty;

    // tick gen
    logic                baud_tick;
    logic                sampling_tick;

    // tx
    logic                start;
    logic [         7:0] tx_data;
    logic                busy;

    // shift register
    logic [   DEPTH-1:0] sh_cnt;
    logic [DEPTH*BW-1:0] i_tx_data_reg;
    assign re = (~empty & ~busy);
    assign we = (~full & i_tx_data_hs);
    assign start = (~empty);
    assign uart_data_control_uart_ready = ~i_tx_data_hs & empty;


    // handshake register
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            i_tx_data_hs <= 1'b0;
        end else begin
            if (uart_data_control_uart_ready && uart_data_control_uart_valid) begin
                i_tx_data_hs <= 1'b1;
            end else begin
                if (sh_cnt == DEPTH - 1) begin
                    i_tx_data_hs <= 1'b0;
                end
            end
        end
    end

    // fifo 이전 i_tx_data shift register
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            sh_cnt <= 0;
            i_tx_data_reg <= 0;
        end else begin
            if (uart_data_control_uart_ready && uart_data_control_uart_valid) begin
                i_tx_data_reg <= i_tx_data;
            end else if (i_tx_data_hs) begin
                i_tx_data_reg <= {8'h0, i_tx_data_reg[(DEPTH)*BW-1:BW]};
                if (sh_cnt == DEPTH - 1) begin
                    sh_cnt <= 0;
                end else begin
                    sh_cnt <= sh_cnt + 1;
                end
            end
        end
    end
    assign wdata = (sh_cnt == 0) ? i_tx_data[7:0] : i_tx_data_reg[7:0];
    sync_fifo #(
        .DEPTH(DEPTH),
        .BW   (BW)
    ) U_TX_FIFO (
        .clk  (clk),
        .rst  (rst),
        .we   (we),
        .re   (re),
        .wdata(wdata),
        .rdata(tx_data),
        .full (full),
        .empty(empty)
    );
    baud_tick_gen #(
        .BAUD_RATE(BAUD_RATE),
        .SAMPLE   (SAMPLE)
    ) U_BAUD_TICK_GEN (
        .clk          (clk),
        .rst          (rst),
        .busy         (busy),
        .baud_tick    (baud_tick),
        .sampling_tick(sampling_tick)
    );
    uart_tx U_TX (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick),
        .start    (start),
        .tx_data  (tx_data),
        .busy     (busy),
        .tx       (tx)
    );
    uart_rx U_RX (
        .clk(clk),
        .rst(rst),
        .sampling_tick(sampling_tick),
        .rx(rx),
        .done(done),
        .o_rx_data(o_rx_data)
    );
endmodule
