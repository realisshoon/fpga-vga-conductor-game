package uart_wrapper_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_wrapper_seq_item.sv"
    `include "uart_wrapper_sequence.sv"
    `include "uart_wrapper_driver.sv"
    `include "uart_wrapper_monitor.sv"
    `include "uart_wrapper_agent.sv"
    `include "uart_wrapper_scoreboard.sv"
    `include "uart_wrapper_coverage.sv"
    `include "uart_wrapper_env.sv"
    `include "uart_wrapper_test.sv"
endpackage
