class rg_detect_agent extends uvm_agent;

    `uvm_component_utils(rg_detect_agent)

    rg_detect_sequencer sequencer;
    rg_detect_driver    driver;
    rg_detect_monitor   monitor;


    function new(string name = "rg_detect_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        sequencer = rg_detect_sequencer::type_id::create("sequencer", this);

        driver = rg_detect_driver::type_id::create("driver", this);

        monitor = rg_detect_monitor::type_id::create("monitor", this);

    endfunction


    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        driver.seq_item_port.connect(sequencer.seq_item_export);

    endfunction

endclass

