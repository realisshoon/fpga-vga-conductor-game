package rg_detect_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `uvm_analysis_imp_decl(_expected)
    `uvm_analysis_imp_decl(_actual)

    `include "rg_detect_item.sv"
    `include "rg_detect_sequencer.sv"
    `include "rg_detect_sequence.sv"
    `include "rg_detect_driver.sv"
    `include "rg_detect_monitor.sv"
    `include "rg_detect_agent.sv"
    `include "rg_detect_scoreboard.sv"
    `include "rg_detect_env.sv"
    `include "rg_detect_test.sv"

endpackage

