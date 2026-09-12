class uart_wrapper_coverage extends uvm_subscriber #(uart_wrapper_seq_item);
    `uvm_component_utils(uart_wrapper_coverage)

    // Byte positions follow UART serialization order (byte0 first).
    // Seven disjoint bins cover all 256 byte values.
    covergroup tx_cg with function sample(logic [63:0] data);
        option.per_instance = 1;
        cp_byte0: coverpoint data[7:0] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte1: coverpoint data[15:8] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte2: coverpoint data[23:16] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte3: coverpoint data[31:24] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte4: coverpoint data[39:32] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte5: coverpoint data[47:40] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte6: coverpoint data[55:48] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
        cp_byte7: coverpoint data[63:56] {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }

        // Adjacent byte pairs: 7 crosses x 49 bins, not an eight-way cross.
        cross_byte0_1: cross cp_byte0, cp_byte1;
        cross_byte1_2: cross cp_byte1, cp_byte2;
        cross_byte2_3: cross cp_byte2, cp_byte3;
        cross_byte3_4: cross cp_byte3, cp_byte4;
        cross_byte4_5: cross cp_byte4, cp_byte5;
        cross_byte5_6: cross cp_byte5, cp_byte6;
        cross_byte6_7: cross cp_byte6, cp_byte7;
    endgroup

    covergroup rx_cg with function sample(logic [7:0] data);
        option.per_instance = 1;
        cp_data: coverpoint data {
            bins \0x00 = {8'h00};
            bins \0x55 = {8'h55};
            bins \0xAA = {8'hAA};
            bins \0xFF = {8'hFF};
            bins low = {[8'h01:8'h54]};
            bins mid = {[8'h56:8'hA9]};
            bins high = {[8'hAB:8'hFE]};
        }
    endgroup

    // One sample per completed TX frame, after the handshake observation window.
    covergroup handshake_cg with function sample(uart_wrapper_seq_item t);
        option.per_instance = 1;
        cp_volume_hs: coverpoint t.volume_hs {
            bins absent = {0};
            bins observed = {1};
        }
        cp_pixel_hs: coverpoint t.pixel_hs {
            bins absent = {0};
            bins observed = {1};
        }
        cp_speed_hs: coverpoint t.speed_hs {
            bins absent = {0};
            bins observed = {1};
        }
        cp_score_hs: coverpoint t.score_hs {
            bins absent = {0};
            bins observed = {1};
        }
        cp_game_state_hs: coverpoint t.game_state_hs {
            bins absent = {0};
            bins observed = {1};
        }
        cp_pattern_state_hs: coverpoint t.pattern_state_hs {
            bins absent = {0};
            bins observed = {1};
        }
        // Six binary flags produce 64 handshake combinations.
        cross_fields: cross cp_volume_hs, cp_pixel_hs, cp_speed_hs, cp_score_hs, cp_game_state_hs, cp_pattern_state_hs;
    endgroup

    covergroup overlap_cg with function sample(bit seen);
        option.per_instance = 1;
        cp_overlap: coverpoint seen {
            bins observed = {1};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        overlap_cg = new();
        handshake_cg = new();
        tx_cg = new();
        rx_cg = new();
    endfunction

    function void write(uart_wrapper_seq_item t);
        if (t.tx_comp) begin
            tx_cg.sample(t.actual_tx_data);
            handshake_cg.sample(t);
        end
        if (t.rx_comp) rx_cg.sample(t.o_rx_data);
        if (t.overlap_seen) overlap_cg.sample(t.overlap_seen);
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", $sformatf("TX/RX overlap coverage : %0.2f%%",
                                  overlap_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("TX handshake coverage : %0.2f%%",
                                  handshake_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("TX handshake cross coverage : %0.2f%%",
                                  handshake_cg.cross_fields.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("TX byte/pair coverage : %0.2f%%",
                                  tx_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("RX byte coverage : %0.2f%%",
                                  rx_cg.get_inst_coverage()), UVM_LOW)
    endfunction
endclass
