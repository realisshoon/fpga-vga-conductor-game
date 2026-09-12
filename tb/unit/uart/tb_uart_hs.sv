`timescale 1ns / 1ps

module tb_uart_hs ();
    localparam BAUD_RATE = 115_200;
    localparam SAMPLE = 16;
    localparam DEPTH = 8;
    localparam BW = 8;
    localparam SAMPLE_PERIOD = 100_000_000 / BAUD_RATE / SAMPLE;
    localparam BIT_PERIOD = SAMPLE_PERIOD * SAMPLE;

    logic                clk;
    logic                rst;
    logic                tx;
    logic                rx;
    logic                uart_data_control_uart_ready;
    logic                uart_data_control_uart_valid;
    logic [DEPTH*BW-1:0] i_tx_data;
    logic [      BW-1:0] o_rx_data;

    uart dut (.*);
    logic [7:0] golden_queue[$];
    logic [7:0] golden_queue_2[$];
    // Tx test
    logic [BW-1:0] tb_rx_data;  // tx deserializing
    logic [BW-1:0] expected_data;
    // Rx test
    logic [BW-1:0] tx_data;  // rx driving
    logic [BW-1:0] expected_data_2;
    int test = 0;
    int tx_pass = 0;
    int tx_fail = 0;
    int rx_pass = 0;
    int rx_fail = 0;

    always #5 clk = ~clk;
    task automatic TX_DRV(int num);
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
        #100000; // 수신단이 마지막 데이터를 다 처리할 때까지 충분히 대기
    endtask

    task automatic TX_SCB();
        forever begin
            @(negedge tx);
            repeat (BIT_PERIOD + BIT_PERIOD / 2) @(posedge clk);
            for (int i = 0; i < 8; i++) begin
                tb_rx_data = {tx, tb_rx_data[7:1]};
                repeat (BIT_PERIOD) @(posedge clk);
            end

            // 큐가 비어있는지 먼저 확인 (에러 방지)
            if (golden_queue.size() == 0) begin
                $error(
                    "[TX_SCB Error] Received UART data, but golden_queue is empty! rx_data = %h",
                    tb_rx_data);
            end else begin
                // 큐 데이터 뽑기
                expected_data = golden_queue.pop_front();

                // 데이터와 정답 비교
                if (tb_rx_data == expected_data) begin
                    $display("[TX_SCB PASS] Match! tb_rx_data = %h",
                             tb_rx_data);
                    tx_pass++;
                end else begin
                    $error("[TX_SCB FAIL] Mismatch! Expected: %h, Received: %h",
                           expected_data, tb_rx_data);
                    tx_fail++;
                end
            end
        end
    endtask


    task automatic RX_DRV(int num);
        repeat (num) begin
            if (std::randomize(tx_data)) begin
                golden_queue_2.push_back(tx_data);
                // margin 
                rx = 1'b1;
                repeat (BIT_PERIOD) @(posedge clk);

                // start bit
                rx = 1'b0;
                repeat (BIT_PERIOD) @(posedge clk);

                // tx active
                for (int i = 0; i < 8; i++) begin
                    rx = tx_data[0];
                    tx_data = {1'b0, tx_data[7:1]};
                    repeat (BIT_PERIOD) @(posedge clk);
                end
                // stop bit
                rx = 1'b1;
                repeat (BIT_PERIOD) @(posedge clk);
            end
        end
        #100000; // 수신단이 마지막 데이터를 다 처리할 때까지 충분히 대기
    endtask

    task automatic RX_SCB();
        forever begin
            wait (dut.done);
            @(posedge clk);
            // 큐에서 꺼냄
            expected_data_2 = golden_queue_2.pop_front();
            @(negedge clk);
            if (o_rx_data == expected_data_2) begin
                $display("[RX_SCB PASS] Match! o_rx_data = %h", o_rx_data);
                rx_pass++;
            end else begin
                $error("[RX_SCB FAIL] Mismatch! Expected: %h, Received: %h",
                       expected_data_2, o_rx_data);
                rx_fail++;
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        clk = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst  = 1'b0;
        test = 100;

        fork
            // [Thread 1] RX드라이버: 데이터를 총 5번 순차적으로 쏨
            begin
                RX_DRV(test);
                $display(
                    "[RX_DRV] All %d data sent. Waiting for receiver to finish...",
                    test);
            end
            // [Thread 2] TX드라이버: 데이터를 총 5번 순차적으로 쏨
            begin
                TX_DRV(test);
                $display(
                    "[TX_DRV] All %d data sent. Waiting for receiver to finish...",
                    test);
            end
            // [Thread 3] 리시버: 무한히 대기하면서 o_rx_data를 감시함
            begin
                forever begin
                    RX_SCB();
                end
            end
            // [Thread 4] 리시버: 무한히 대기하면서 tx 라인을 감시함
            begin
                forever begin
                    TX_SCB();
                end
            end
        join_any

        $display(
            "--------------------------------------------------------------------");
        $display(
            "---------------------    RANDOM test    ----------------------------");
        $display("total: %d", tx_pass + rx_pass + tx_fail + rx_fail);
        $display("pass: %d", tx_pass + rx_pass);
        $display("fail: %d", tx_fail + rx_fail);
        $display(
            "--------------------------------------------------------------------");

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $finish;


    end



endmodule
