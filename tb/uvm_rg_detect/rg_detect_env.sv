class rg_detect_env extends uvm_env;

    `uvm_component_utils(rg_detect_env)

    rg_detect_agent      agent;
    rg_detect_scoreboard scoreboard;


    function new(string name = "rg_detect_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent = rg_detect_agent::type_id::create("agent", this);

        scoreboard = rg_detect_scoreboard::type_id::create("scoreboard", this);

    endfunction


    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        agent.driver.expected_ap.connect(scoreboard.expected_export);

        agent.monitor.actual_ap.connect(scoreboard.actual_export);

    endfunction

endclass

