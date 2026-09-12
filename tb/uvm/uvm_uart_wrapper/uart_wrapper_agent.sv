class uart_wrapper_agent extends uvm_agent;
    `uvm_component_utils(uart_wrapper_agent)

    uvm_sequencer#(uart_wrapper_seq_item) tx_sqr;
    uvm_sequencer#(uart_wrapper_seq_item) rx_sqr;
    uart_wrapper_driver    drv;
    uart_wrapper_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // use basic sequencer
        tx_sqr = uvm_sequencer#(uart_wrapper_seq_item)::type_id::create(
            "TX_SQR", this);
        rx_sqr = uvm_sequencer#(uart_wrapper_seq_item)::type_id::create(
            "RX_SQR", this);
        // monitor, drv connect
        mon = uart_wrapper_monitor::type_id::create("MON", this);
        drv = uart_wrapper_driver::type_id::create("DRV", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(tx_sqr.seq_item_export);
        // driver의 port와 새로운 matching
        drv.rx_item_port.connect(rx_sqr.seq_item_export);
    endfunction
endclass
