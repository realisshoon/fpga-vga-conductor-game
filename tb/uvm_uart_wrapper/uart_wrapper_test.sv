class uart_wrapper_base_test extends uvm_test;
    `uvm_component_utils(uart_wrapper_base_test)

    uart_wrapper_env env;

    function new(string name = "uart_wrapper_base_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_wrapper_env::type_id::create("ENV", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
endclass

class uart_wrapper_random_test extends uart_wrapper_base_test;

    `uvm_component_utils(uart_wrapper_random_test)

    function new(string name = "uart_wrapper_random_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_wrapper_random_sequence tx_seq;
        uart_wrapper_random_sequence rx_seq;
        int unsigned tx_num = 500;
        int unsigned rx_num = 100;

        phase.raise_objection(this);

        tx_seq = uart_wrapper_random_sequence::type_id::create("TX_SEQ");
        rx_seq = uart_wrapper_random_sequence::type_id::create("RX_SEQ");

        tx_seq.num_frames = tx_num;
        rx_seq.num_frames = rx_num;

        // tx
        fork
            tx_seq.start(env.agt.tx_sqr);
            rx_seq.start(env.agt.rx_sqr);
        join

        wait ((env.scb.tx_pass + env.scb.tx_fail == tx_num) 
        && (env.scb.rx_pass + env.scb.rx_fail == rx_num));

        phase.drop_objection(this);
    endtask

endclass

class uart_wrapper_rx_pattern_test extends uart_wrapper_base_test;

    `uvm_component_utils(uart_wrapper_rx_pattern_test)

    function new(string name = "uart_wrapper_rx_patten_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_wrapper_rx_pattern_sequence seq;

        phase.raise_objection(this);
        seq =
            uart_wrapper_rx_pattern_sequence::type_id::create("RX_PATTERN_SEQ");

        // rx
        fork : rx_test
            begin
                seq.start(env.agt.rx_sqr);
                wait (env.scb.rx_pass + env.scb.rx_fail == 4);
            end
            begin
                repeat (100_000) @(env.agt.drv.vif.drv_cb);
                `uvm_fatal("RX_TIMEOUT", "RX pattern test timelimit")
            end
        join_any
        disable rx_test;

        phase.drop_objection(this);
    endtask

endclass

class uart_wrapper_tx_field_test extends uart_wrapper_base_test;

    `uvm_component_utils(uart_wrapper_tx_field_test)

    function new(string name = "uart_wrapper_tx_field_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        int unsigned tx_num = 14;
        uart_wrapper_tx_field_sequence seq;

        phase.raise_objection(this);
        seq = uart_wrapper_tx_field_sequence::type_id::create("TX_FIELD_SEQ");

        seq.start(env.agt.tx_sqr);
        wait (env.scb.tx_pass + env.scb.tx_fail == tx_num);

        phase.drop_objection(this);
    endtask

endclass

class uart_wrapper_full_duplex_test extends uart_wrapper_base_test;

    `uvm_component_utils(uart_wrapper_full_duplex_test)

    function new(string name = "uart_wrapper_full_duplex_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_wrapper_random_sequence tx_seq;
        uart_wrapper_random_sequence rx_seq;
        int unsigned frame = 5;
        int unsigned rx_per_tx = 8;

        phase.raise_objection(this);

        tx_seq = uart_wrapper_random_sequence::type_id::create("TX_SEQ");
        rx_seq = uart_wrapper_random_sequence::type_id::create("RX_SEQ");
        tx_seq.num_frames = frame;
        rx_seq.num_frames = rx_per_tx;

        fork
            tx_seq.start(env.agt.tx_sqr);

            begin
                repeat (frame) begin
                    // 프레임 기준 sync를 새 클럭에서 관측
                    do begin
                        @(env.agt.mon.vif.mon_cb);
                    end while (env.agt.mon.vif.mon_cb.pixel_dec_sync !== 1'b1);

                    // 해당 TX 프레임의 첫 start bit 대기
                    do begin
                        @(env.agt.mon.vif.mon_cb);
                    end while (env.agt.mon.vif.mon_cb.tx !== 1'b0);

                    // 이번 TX 프레임 동안 RX 8바이트 전송
                    rx_seq.start(env.agt.rx_sqr);
                end
            end
        join

        wait ((env.scb.tx_pass + env.scb.tx_fail == frame) 
        && (env.scb.rx_pass + env.scb.rx_fail == rx_per_tx * frame));

        phase.drop_objection(this);
    endtask

endclass

class uart_wrapper_tx_byte_pair_test extends uart_wrapper_base_test;
    `uvm_component_utils(uart_wrapper_tx_byte_pair_test)

    function new(string name = "uart_wrapper_tx_byte_pair_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_wrapper_tx_byte_pair_sequence seq;
        phase.raise_objection(this);
        seq = uart_wrapper_tx_byte_pair_sequence::type_id::create("TX_BYTE_PAIR_SEQ");
        fork : byte_pair_test
            begin
                seq.start(env.agt.tx_sqr);
                wait (env.scb.tx_pass + env.scb.tx_fail == 49);
                // Let the synchronous analysis-port broadcast finish sampling coverage.
                @(env.agt.mon.vif.mon_cb);
                if (env.cov.tx_cg.get_inst_coverage() < 100.0)
                    `uvm_error("TX_PAIR_COV", "TX byte/pair coverage did not reach 100%")
            end
            begin
                // 2 seconds at 100 MHz, sufficient for 49 frames at 30 Hz.
                repeat (200_000_000) @(env.agt.mon.vif.mon_cb);
                `uvm_fatal("TX_PAIR_TIMEOUT", "TX byte pair test timed out")
            end
        join_any
        disable byte_pair_test;
        phase.drop_objection(this);
    endtask
endclass
