class uart_wrapper_driver extends uvm_driver #(uart_wrapper_seq_item);
    localparam BAUD_RATE = 115_200;
    localparam SAMPLE = 16;
    localparam DEPTH = 8;
    localparam BW = 8;
    localparam SAMPLE_PERIOD = 100_000_000 / BAUD_RATE / SAMPLE;
    localparam BIT_PERIOD = SAMPLE_PERIOD * SAMPLE;

    `uvm_component_utils(uart_wrapper_driver)

    virtual uart_wrapper_interface vif;

    // uvm_driver는 기본적으로 1개의 sequencer와의 연결포트를 지정함.
    // 그것이 seq_item_port;
    // 그래서 1개의 추가 포트를 생성함

    // new port for Rx
    // Cf!!!!!!!!!!!!!!!!
    // 새로운 포트를 형성했으니, 생성자를 추가로 불러주어야 한다.
    uvm_seq_item_pull_port #(uart_wrapper_seq_item) rx_item_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        rx_item_port = new("rx_item_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_wrapper_interface)::get(
                this, "", "vif", vif
            ))
            `uvm_fatal(get_type_name(), "Cannot find virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        // reset
        // add reset task
        wait (vif.rst === 1'b0);
        vif.drv_cb.volume_uart_valid     <= 1'b0;
        vif.drv_cb.xy_uart_valid         <= 1'b0;
        vif.drv_cb.stick_control_valid   <= 1'b0;
        vif.drv_cb.score_control_valid   <= 1'b0;
        vif.drv_cb.game_control_valid    <= 1'b0;
        vif.drv_cb.pattern_control_valid <= 1'b0;

        vif.drv_cb.rx                    <= 1'b1;
        fork
            drive_field();
            drive_rx();
        join

    endtask

    task automatic drive_rx();
        uart_wrapper_seq_item rx_req;
        @(vif.drv_cb);
        vif.drv_cb.rx <= 1'b1;
        repeat (BIT_PERIOD) @(vif.drv_cb);

        forever begin
            rx_item_port.get_next_item(rx_req);
            vif.expected_rx_data = rx_req.expected_rx_data;
            vif.drv_cb.rx <= 1'b0;
            repeat (BIT_PERIOD) @(vif.drv_cb);
            for (int j = 0; j < 8; j++) begin
                vif.drv_cb.rx <= rx_req.expected_rx_data[j];
                repeat (BIT_PERIOD) @(vif.drv_cb);
            end
            vif.drv_cb.rx <= 1'b1;
            repeat (BIT_PERIOD) @(vif.drv_cb);
            rx_item_port.item_done();
        end
    endtask

    //=================================== driving task ============================================
    task automatic drive_field();
        forever begin
            seq_item_port.get_next_item(req);
            // h_sync tick 이후
            do begin
                @(vif.drv_cb);
            end while (vif.drv_cb.pixel_dec_sync !== 1'b1);

            // field data random driving & hand shake
            fork : driving
                begin : field_driving
                    fork
                        if (req.volume_enable) drive_volume(req);
                        if (req.pixel_enable) drive_pixel(req);
                        if (req.speed_enable) drive_speed(req);
                        if (req.score_enable) drive_score(req);
                        if (req.game_state_enable) drive_game_state(req);
                        if (req.pattern_state_enable) drive_pattern_state(req);
                    join
                end

                begin : timeout
                    repeat (16) @(vif.drv_cb);
                end
            join_any
            disable driving;
            vif.drv_cb.volume_uart_valid     <= 1'b0;
            vif.drv_cb.xy_uart_valid         <= 1'b0;
            vif.drv_cb.stick_control_valid   <= 1'b0;
            vif.drv_cb.score_control_valid   <= 1'b0;
            vif.drv_cb.game_control_valid    <= 1'b0;
            vif.drv_cb.pattern_control_valid <= 1'b0;
            seq_item_port.item_done();
        end
    endtask
    task drive_volume(uart_wrapper_seq_item tr);
        // drive after random delay
        repeat (tr.volume_delay) @(vif.drv_cb);
        vif.drv_cb.i_volume_level    <= tr.i_volume_level;
        vif.drv_cb.volume_uart_valid <= 1'b1;
        // 1 cycle tick 유지
        @(vif.drv_cb);

        // handshake 조건
        if (vif.drv_cb.volume_uart_ready) vif.drv_cb.volume_uart_valid <= 1'b0;
    endtask

    task drive_pixel(uart_wrapper_seq_item tr);
        repeat (tr.pixel_delay) @(vif.drv_cb);
        vif.drv_cb.i_pixel       <= tr.i_pixel;
        vif.drv_cb.xy_uart_valid <= 1'b1;
        @(vif.drv_cb);

        // handshake 조건
        if (vif.drv_cb.xy_uart_ready) vif.drv_cb.xy_uart_valid <= 1'b0;
    endtask

    task drive_speed(uart_wrapper_seq_item tr);
        repeat (tr.speed_delay) @(vif.drv_cb);
        vif.drv_cb.i_speed             <= tr.i_speed;
        vif.drv_cb.stick_control_valid <= 1'b1;
        @(vif.drv_cb);

        // handshake 조건
        if (vif.drv_cb.stick_control_ready)
            vif.drv_cb.stick_control_valid <= 1'b0;
    endtask

    task drive_score(uart_wrapper_seq_item tr);
        repeat (tr.score_delay) @(vif.drv_cb);
        vif.drv_cb.i_score             <= tr.i_score;
        vif.drv_cb.score_control_valid <= 1'b1;
        @(vif.drv_cb);

        // handshake 조건
        if (vif.drv_cb.score_control_ready)
            vif.drv_cb.score_control_valid <= 1'b0;
    endtask

    task drive_game_state(uart_wrapper_seq_item tr);
        repeat (tr.game_state_delay) @(vif.drv_cb);
        vif.drv_cb.i_game_state       <= tr.i_game_state;
        vif.drv_cb.game_control_valid <= 1'b1;
        @(vif.drv_cb);

        // handshake 조건
        if (vif.drv_cb.game_control_ready)
            vif.drv_cb.game_control_valid <= 1'b0;
    endtask
    task drive_pattern_state(uart_wrapper_seq_item tr);
        repeat (tr.pattern_state_delay) @(vif.drv_cb);
        vif.drv_cb.i_pattern_state       <= tr.i_pattern_state;
        vif.drv_cb.pattern_control_valid <= 1'b1;
        @(vif.drv_cb);

        // handshake 조건
        if (vif.drv_cb.pattern_control_ready)
            vif.drv_cb.pattern_control_valid <= 1'b0;
    endtask


endclass
