class uart_wrapper_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_wrapper_scoreboard)

    uvm_analysis_imp #(uart_wrapper_seq_item, uart_wrapper_scoreboard) imp;

    // scoreboard guide
    int tx_pass = 0;
    int tx_fail = 0;
    int rx_pass = 0;
    int rx_fail = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    function void write(uart_wrapper_seq_item tr);
        if (tr.tx_comp == 1'b1) begin
            TX_SCB(tr);
        end

        if (tr.rx_comp == 1'b1) begin
            RX_SCB(tr);
        end
    endfunction

    function void TX_SCB(uart_wrapper_seq_item tr);
        if (tr.expected_tx_data === tr.actual_tx_data) begin
            tx_pass++;
            `uvm_info(get_type_name(), $sformatf(
                                           "TX PASS! : expected data = 0x%02h",
                                           tr.expected_tx_data), UVM_MEDIUM)
        end else begin
            tx_fail++;
            `uvm_error(get_type_name(), $sformatf(
                       "TX FAIL! : expected_data = 0x%02h, actual_data = 0x%02h",
                       tr.expected_tx_data,
                       tr.actual_tx_data
                       ))
        end
    endfunction

    function void RX_SCB(uart_wrapper_seq_item tr);
        if (tr.expected_rx_data === tr.o_rx_data) begin
            rx_pass++;
            `uvm_info(get_type_name(), $sformatf(
                                           "RX PASS! : expected data = 0x%02h",
                                           tr.expected_rx_data), UVM_MEDIUM)
        end else begin
            rx_fail++;
            `uvm_error(get_type_name(), $sformatf(
                       "RX FAIL! : expected_data = 0x%02h, actual_data = 0x%02h",
                       tr.expected_rx_data,
                       tr.o_rx_data
                       ))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "=======================================", UVM_LOW)
        `uvm_info("SCB", "========== Scoreboard report ==========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  total  test : %0d", tx_pass + rx_pass + tx_fail + rx_fail), UVM_LOW)
        `uvm_info("SCB", $sformatf("  total  pass : %0d", tx_pass + rx_pass),
                  UVM_LOW)
        `uvm_info("SCB", $sformatf("  total  fail : %0d", tx_fail + rx_fail),
                  UVM_LOW)
        `uvm_info("SCB", $sformatf("  Tx  pass : %0d", tx_pass), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Tx  fail : %0d", tx_fail), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Rx  pass : %0d", rx_pass), UVM_LOW)
        `uvm_info("SCB", $sformatf("  Rx  fail : %0d", rx_fail), UVM_LOW)
        `uvm_info("SCB", "=======================================", UVM_LOW)
    endfunction
endclass
