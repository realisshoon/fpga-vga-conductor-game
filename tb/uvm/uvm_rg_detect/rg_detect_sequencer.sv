class rg_detect_sequencer extends uvm_sequencer #(rg_detect_item);

    `uvm_component_utils(rg_detect_sequencer)

    function new(string name = "rg_detect_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

