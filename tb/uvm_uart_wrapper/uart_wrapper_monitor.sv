class uart_wrapper_monitor extends uvm_monitor;
    localparam BAUD_RATE = 115_200;
    localparam SAMPLE = 16;
    localparam DEPTH = 8;
    localparam BW = 8;
    localparam SAMPLE_PERIOD = 100_000_000 / BAUD_RATE / SAMPLE;
    localparam BIT_PERIOD = SAMPLE_PERIOD * SAMPLE;

    `uvm_component_utils(uart_wrapper_monitor)

    virtual uart_wrapper_interface vif;
    uvm_analysis_port #(uart_wrapper_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_wrapper_interface)::get(
                this, "", "vif", vif
            ))
            `uvm_fatal(get_type_name(), "Cannot find virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            monitor_tx();
            monitor_rx();
            monitor_overlap();
        join
    endtask

    // Fixed-baud 8N1: track ten bit periods from each observed start edge.
    task automatic monitor_overlap();
        int unsigned tx_left = 0;
        int unsigned rx_left = 0;
        logic prev_tx = 1'bx;
        logic prev_rx = 1'bx;
        bit overlapping = 0;
        bit overlap_now;
        uart_wrapper_seq_item overlap_tr;

        forever begin
            @(vif.mon_cb);
            if (vif.rst !== 1'b0) begin
                tx_left = 0;
                rx_left = 0;
                prev_tx = 1'bx;
                prev_rx = 1'bx;
                overlapping = 0;
            end else begin
                if (tx_left > 0) tx_left--;
                if (rx_left > 0) rx_left--;

                // Ignore data-bit edges while a byte frame is in progress.
                if (tx_left == 0 && prev_tx === 1'b1 &&
                    vif.mon_cb.tx === 1'b0)
                    tx_left = 10 * BIT_PERIOD;
                if (rx_left == 0 && prev_rx === 1'b1 &&
                    vif.mon_cb.rx === 1'b0)
                    rx_left = 10 * BIT_PERIOD;

                overlap_now = (tx_left > 0 && rx_left > 0);
                if (overlap_now && !overlapping) begin
                    overlap_tr = uart_wrapper_seq_item::type_id::create("overlap_tr");
                    overlap_tr.tx_comp = 1'b0;
                    overlap_tr.rx_comp = 1'b0;
                    overlap_tr.overlap_seen = 1'b1;
                    ap.write(overlap_tr);
                end
                overlapping = overlap_now;
                prev_tx = vif.mon_cb.tx;
                prev_rx = vif.mon_cb.rx;
            end
        end
    endtask

    task automatic monitor_rx();
        uart_wrapper_seq_item rx_tr;
        fork : monitoring_rx
            forever begin
                @(vif.mon_cb);
                if (vif.mon_cb.rx_done) begin
                    rx_tr = uart_wrapper_seq_item::type_id::create("rx_tr");
                    rx_tr.expected_rx_data = vif.expected_rx_data;
                    rx_tr.rx_comp = 1'b0;
                    @(vif.mon_cb);
                    rx_tr.o_rx_data = vif.mon_cb.o_rx_data;
                    rx_tr.rx_comp   = 1'b1;
                    rx_tr.tx_comp   = 1'b0;
                    ap.write(rx_tr);
                end
            end
        join
    endtask

    task automatic monitor_tx();
        uart_wrapper_seq_item tx_tr;
        // simulation시 최초 데이터 전송시 tx_tr 은 0을 담고 있다.
        uart_wrapper_seq_item past_tx_tr;
        past_tx_tr = uart_wrapper_seq_item::type_id::create("past_tx_tr");
        past_tx_tr.expected_tx_data = '0;
        forever begin
            // frame 시작을 대기
            wait (vif.mon_cb.pixel_dec_sync);
            // 그 이후 transaction을 생성
            tx_tr = uart_wrapper_seq_item::type_id::create("tx_tr");
            // 생성하면 일단 비교여부 0으로 초기화
            // past_tx_tr expected data로 초기화
            tx_tr.expected_tx_data = past_tx_tr.expected_tx_data;
            tx_tr.tx_comp = 1'b0;
            tx_tr.rx_comp = 1'b0;
            tx_tr.volume_hs = 1'b0;
            tx_tr.pixel_hs = 1'b0;
            tx_tr.speed_hs = 1'b0;
            tx_tr.score_hs = 1'b0;
            tx_tr.game_state_hs = 1'b0;
            tx_tr.pattern_state_hs = 1'b0;

            // field task 돌리기
            // 이러면 tx_tr은 current 값으로 update됨.
            monitor_field_frame(tx_tr);

            // 전송 이전에 current 값 golden으로 update
            past_tx_tr.expected_tx_data = tx_tr.expected_tx_data;

            // tx 동작 후 acutual data sampling
            monitor_tx_line(tx_tr);
            tx_tr.tx_comp = 1'b1;

            // ap통해서 보내기
            ap.write(tx_tr);
        end
    endtask

    task automatic monitor_tx_line(uart_wrapper_seq_item tr);
        logic [7:0] tx_data;
        for (int i = 0; i < 8; i++) begin
            wait (vif.mon_cb.tx == 1'b0);
            repeat (BIT_PERIOD + BIT_PERIOD / 2) @(vif.mon_cb);
            for (int j = 0; j < 8; j++) begin
                tx_data = {vif.mon_cb.tx, tx_data[7:1]};
                repeat (BIT_PERIOD) @(vif.mon_cb);
            end
            tr.actual_tx_data[i*8+:8] = tx_data;
        end
    endtask

    task automatic monitor_field_frame(uart_wrapper_seq_item tr);
        fork : waiting_handshake
            begin : hand_shake_monitoring_thread
                fork
                    monitor_volume(tr);
                    monitor_pixel(tr);
                    monitor_speed(tr);
                    monitor_score(tr);
                    monitor_game_state(tr);
                    monitor_pattern_state(tr);
                join
            end

            begin : timeout_thread // 16cycle이내에 handshake가 없다면 그대로 전송
                repeat (17) @(vif.mon_cb);
            end
        join_any
        disable waiting_handshake;

        // sampling 한걸 전송한다. 이걸 기다려야함.
        // 09/05에 추가 예정
    endtask

    task automatic monitor_volume(uart_wrapper_seq_item tr);
        wait (vif.mon_cb.volume_uart_ready && vif.mon_cb.volume_uart_valid);
        tr.volume_hs = 1'b1;
        tr.i_volume_level = vif.mon_cb.i_volume_level;  // for coverage
        tr.expected_tx_data[18:12] = vif.mon_cb.i_volume_level;  // for scoreboard
    endtask

    task automatic monitor_pixel(uart_wrapper_seq_item tr);
        wait (vif.mon_cb.xy_uart_ready && vif.mon_cb.xy_uart_valid);
        tr.pixel_hs = 1'b1;
        tr.i_pixel                 = vif.mon_cb.i_pixel;  // for coverage
        tr.expected_tx_data[61:22] = vif.mon_cb.i_pixel;  // for scoreboard
    endtask

    task automatic monitor_speed(uart_wrapper_seq_item tr);
        wait (vif.mon_cb.stick_control_ready && vif.mon_cb.stick_control_valid);
        tr.speed_hs = 1'b1;
        tr.i_speed                = vif.mon_cb.i_speed;  // for coverage
        tr.expected_tx_data[11:4] = vif.mon_cb.i_speed;  // for scoreboard
    endtask

    task automatic monitor_score(uart_wrapper_seq_item tr);
        wait (vif.mon_cb.score_control_ready && vif.mon_cb.score_control_valid);
        tr.score_hs = 1'b1;
        tr.i_score               = vif.mon_cb.i_score;  // for coverage
        tr.expected_tx_data[3:0] = vif.mon_cb.i_score;  // for scoreboard
    endtask

    task automatic monitor_game_state(uart_wrapper_seq_item tr);
        wait (vif.mon_cb.game_control_ready && vif.mon_cb.game_control_valid);
        tr.game_state_hs = 1'b1;
        tr.i_game_state = vif.mon_cb.i_game_state;  // for coverage
        tr.expected_tx_data[63:62] = vif.mon_cb.i_game_state;  // for scoreboard
    endtask

    task automatic monitor_pattern_state(uart_wrapper_seq_item tr);
        wait (vif.mon_cb.pattern_control_ready && vif.mon_cb.pattern_control_valid);
        tr.pattern_state_hs = 1'b1;
        tr.i_pattern_state = vif.mon_cb.i_pattern_state;  // for coverage
        tr.expected_tx_data[21:19] = vif.mon_cb.i_pattern_state;  // for scoreboard
    endtask
endclass
