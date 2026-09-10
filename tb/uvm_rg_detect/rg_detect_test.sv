class rg_detect_test extends uvm_test;

    `uvm_component_utils(rg_detect_test)

    rg_detect_env env;


    function new(string name = "rg_detect_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = rg_detect_env::type_id::create("env", this);

    endfunction


    task run_phase(uvm_phase phase);

        rg_detect_sequence seq;

        phase.raise_objection(this);

        `uvm_info(
            "RG_DETECT_TEST",
            "RG_detect UVM regression START : RED/GREEN + XY position/size variation + FRAME END + UART data + READY delay/handshake",
            UVM_LOW)

        seq = rg_detect_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        `uvm_info("RG_DETECT_TEST", "RG_detect UVM verification DONE", UVM_LOW)

        phase.drop_objection(this);

    endtask

endclass

