class uart_wrapper_env extends uvm_env;
    `uvm_component_utils(uart_wrapper_env)

    uart_wrapper_agent      agt;
    uart_wrapper_scoreboard scb;
    uart_wrapper_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = uart_wrapper_agent::type_id::create("AGT", this);
        scb = uart_wrapper_scoreboard::type_id::create("SCB", this);
        cov = uart_wrapper_coverage::type_id::create("COV", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass
