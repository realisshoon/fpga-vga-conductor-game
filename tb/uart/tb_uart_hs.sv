`timescale 1ns / 1ps

module tb_uart_hs ();
    localparam BAUD_RATE = 115_200;
    localparam SAMPLE = 16;
    localparam DEPTH = 8;
    localparam BW = 8;

    logic                clk;
    logic                rst;
    logic                tx;
    logic                rx;
    logic                uart_data_control_uart_ready;
    logic                uart_data_control_uart_valid;
    logic [DEPTH*BW-1:0] i_tx_data;
    logic  [BW-1:0] o_rx_data;

    uart dut (.*);
    logic [7:0] golden_queue[$];
    logic [BW-1:0] rx_data;
    logic [BW-1:0] expected_data;

    always #5 clk = ~clk;
    task HS(int num);
        repeat (num) begin
            wait (uart_data_control_uart_ready == 1'b1);
            if (std::randomize(i_tx_data)) begin
                uart_data_control_uart_valid <= 1;
                for (int i = 0; i < DEPTH; i++) begin
                    golden_queue.push_back(i_tx_data[i*BW+:BW]);
                end
                wait (uart_data_control_uart_ready == 1'b0);
                @(posedge clk);
                uart_data_control_uart_valid <= 0;
            end
        end
    endtask

    task TX_SCB();
        forever begin
            wait (tx == 1'b0);
            for (int i = 0; i < 10; i++) begin
                repeat (100_000_000 / BAUD_RATE / 2) @(posedge clk);
                if (i > 0 && i < 9) begin
                    rx_data <= {tx, rx_data[7:1]};
                end
                repeat (100_000_000 / BAUD_RATE / 2) @(posedge clk);
            end

            // 큐가 비어있는지 먼저 확인 (에러 방지)
            if (golden_queue.size() == 0) begin
                $error(
                    "[Scoreboard Error] Received UART data, but golden_queue is empty! rx_data = %h",
                    rx_data);
            end else begin
                // 큐 데이터 뽑기
                expected_data = golden_queue.pop_front();

                // 데이터와 정답 비교
                if (rx_data == expected_data) begin
                    $display("[Scoreboard PASS] Match! rx_data = %h", rx_data);
                end else begin
                    $error(
                        "[Scoreboard FAIL] Mismatch! Expected: %h, Received: %h",
                        expected_data, rx_data);
                end
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        clk = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        fork
            // [Thread 1] 드라이버: 데이터를 총 5번 순차적으로 쏨
            begin
                HS(5);
                // 필요시 데이터 간의 딜레이 추가 가능
                $display(
                    "[Driver] All 5 data sent. Waiting for receiver to finish...");
                #100000; // 수신단이 마지막 데이터를 다 처리할 때까지 충분히 대기
            end

            // [Thread 2] 리시버: 무한히 대기하면서 tx 라인을 감시함
            begin
                forever begin
                    TX_SCB();
                end
            end
        join_any

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $finish;


    end



endmodule
