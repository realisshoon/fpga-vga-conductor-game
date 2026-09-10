class rg_detect_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(rg_detect_scoreboard)

    uvm_analysis_imp_expected #(rg_detect_item, rg_detect_scoreboard) expected_export;

    uvm_analysis_imp_actual #(rg_detect_item, rg_detect_scoreboard)   actual_export;

    rg_detect_item                                                    expected_q            [$];
    rg_detect_item                                                    actual_q              [$];

    int unsigned                                                      compared_count;
    int unsigned                                                      pass_count;
    int unsigned                                                      error_count;

    int unsigned                                                      red_only_count;
    int unsigned                                                      green_only_count;
    int unsigned                                                      both_count;

    int unsigned                                                      immediate_count;
    int unsigned                                                      delayed_count;


    // Functional coverage sampling state.
    int unsigned                                                      cg_object_state;
    int                                                               cg_stick_x;
    int                                                               cg_stick_y;
    int                                                               cg_hand_x;
    int                                                               cg_hand_y;
    int                                                               cg_ready_delay;

    int                                                               cg_sentinel_to_vsync;
    int                                                               cg_vsync_to_valid;
    int                                                               cg_valid_to_handshake;

    bit                                                               cg_uart_pack_ok;
    bit                                                               cg_payload_stable;


    covergroup rg_detect_cg;

        option.per_instance = 1;

        // Object-state coverage.
        object_state_cp: coverpoint cg_object_state {
            bins RED_ONLY = {2'b10}; bins GREEN_ONLY = {2'b01}; bins BOTH = {2'b11};
        }

        // Stick coordinate regions.
        stick_x_cp: coverpoint cg_stick_x {
            bins LEFT = {[0 : 106]};
            bins CENTER = {[107 : 212]};
            bins RIGHT = {[213 : 319]};
            bins INVALID = {1023};
        }

        stick_y_cp: coverpoint cg_stick_y {
            bins TOP = {[0 : 79]};
            bins MIDDLE = {[80 : 159]};
            bins BOTTOM = {[160 : 239]};
            bins INVALID = {1023};
        }

        // Hand coordinate regions.
        hand_x_cp: coverpoint cg_hand_x {
            bins LEFT = {[0 : 106]};
            bins CENTER = {[107 : 212]};
            bins RIGHT = {[213 : 319]};
            bins INVALID = {1023};
        }

        hand_y_cp: coverpoint cg_hand_y {
            bins TOP = {[0 : 79]};
            bins MIDDLE = {[80 : 159]};
            bins BOTTOM = {[160 : 239]};
            bins INVALID = {1023};
        }

        // READY delay bins.
        ready_delay_cp: coverpoint cg_ready_delay {
            bins IMMEDIATE = {0}; bins SHORT = {[1 : 2]}; bins MEDIUM = {[3 : 5]};
        }

        // Frame-end to o_vsync timing.
        sentinel_to_vsync_cp: coverpoint cg_sentinel_to_vsync {
            bins EXPECTED = {1};
        }

        // o_vsync to VALID timing.
        vsync_to_valid_cp: coverpoint cg_vsync_to_valid {
            bins EXPECTED = {1};
        }

        // VALID/READY handshake latency.
        valid_to_handshake_cp: coverpoint cg_valid_to_handshake {
            bins IMMEDIATE = {0}; bins DELAYED = {[1 : 5]};
        }

        // UART payload packing.
        uart_pack_cp: coverpoint cg_uart_pack_ok {
            bins PASS = {1'b1};
        }

        // Payload stability during backpressure.
        payload_stable_cp: coverpoint cg_payload_stable {
            bins PASS = {1'b1};
        }

        // Every object state must see each READY-delay bin.
        object_ready_cross: cross object_state_cp, ready_delay_cp;

    endgroup


    function new(string name = "rg_detect_scoreboard", uvm_component parent = null);

        super.new(name, parent);

        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);

        rg_detect_cg = new();

    endfunction


    function void write_expected(rg_detect_item tr);

        rg_detect_item c;

        $cast(c, tr.clone());
        expected_q.push_back(c);

        compare_available();

    endfunction


    function void write_actual(rg_detect_item tr);

        rg_detect_item c;

        c                 = rg_detect_item::type_id::create("actual_copy");

        c.frame_id        = tr.frame_id;
        c.act_stick_x     = tr.act_stick_x;
        c.act_stick_y     = tr.act_stick_y;
        c.act_hand_x      = tr.act_hand_x;
        c.act_hand_y      = tr.act_hand_y;
        c.act_o_pixel     = tr.act_o_pixel;
        c.vsync_seen      = tr.vsync_seen;
        c.valid_seen      = tr.valid_seen;
        c.handshake_seen  = tr.handshake_seen;
        c.payload_stable  = tr.payload_stable;
        c.sentinel_cycle  = tr.sentinel_cycle;
        c.vsync_cycle     = tr.vsync_cycle;
        c.valid_cycle     = tr.valid_cycle;
        c.handshake_cycle = tr.handshake_cycle;

        actual_q.push_back(c);

        compare_available();

    endfunction


    function void compare_available();

        rg_detect_item exp;
        rg_detect_item act;

        while ((expected_q.size() > 0) && (actual_q.size() > 0)) begin

            exp = expected_q.pop_front();
            act = actual_q.pop_front();

            compare_frame(exp, act);

        end

    endfunction


    function string object_name(bit red_en, bit green_en);

        case ({
            red_en, green_en
        })
            2'b11:   return "BOTH";
            2'b10:   return "RED";
            2'b01:   return "GREEN";
            default: return "NONE";
        endcase

    endfunction


    function void compare_frame(rg_detect_item exp, rg_detect_item act);

        bit coord_ok;
        bit uart_pack_ok;
        bit frame_timing_ok;
        bit handshake_ok;
        bit frame_ok;

        int sentinel_to_vsync;
        int vsync_to_valid;
        int valid_to_handshake;

        compared_count++;


        // RED/GREEN detection result to Stick/Hand coordinates.
        coord_ok =
            (exp.exp_stick_x === act.act_stick_x) &&
            (exp.exp_stick_y === act.act_stick_y) &&
            (exp.exp_hand_x  === act.act_hand_x ) &&
            (exp.exp_hand_y  === act.act_hand_y );


        // UART payload: {stick_x, stick_y, hand_x, hand_y}.
        uart_pack_ok = (exp.exp_o_pixel === act.act_o_pixel);


        // Frame-end timing is measured in monitor clock samples.
        sentinel_to_vsync = act.vsync_cycle - act.sentinel_cycle;

        vsync_to_valid = act.valid_cycle - act.vsync_cycle;

        frame_timing_ok =
            act.vsync_seen &&
            act.valid_seen &&
            (sentinel_to_vsync == 1) &&
            (vsync_to_valid == 1);


        // VALID/READY handshake latency.
        valid_to_handshake = act.handshake_cycle - act.valid_cycle;

        if (exp.ready_delay == 0) begin

            handshake_ok = act.handshake_seen && (valid_to_handshake == 0);

        end else begin

            handshake_ok = act.handshake_seen && (valid_to_handshake > 0) && act.payload_stable;

        end


        frame_ok = coord_ok && uart_pack_ok && frame_timing_ok && handshake_ok;


        // Sample functional coverage.
        cg_object_state = {exp.red_en, exp.green_en};

        cg_stick_x = act.act_stick_x;
        cg_stick_y = act.act_stick_y;
        cg_hand_x = act.act_hand_x;
        cg_hand_y = act.act_hand_y;

        cg_ready_delay = exp.ready_delay;

        cg_sentinel_to_vsync = sentinel_to_vsync;
        cg_vsync_to_valid = vsync_to_valid;
        cg_valid_to_handshake = valid_to_handshake;

        cg_uart_pack_ok = uart_pack_ok;
        cg_payload_stable = act.payload_stable;

        rg_detect_cg.sample();


        // Count exercised scenarios.
        case ({
            exp.red_en, exp.green_en
        })
            2'b10:   red_only_count++;
            2'b01:   green_only_count++;
            2'b11:   both_count++;
            default: ;
        endcase

        if (exp.ready_delay == 0) immediate_count++;
        else delayed_count++;


        if (frame_ok) begin

            pass_count++;
            if ($test$plusargs("SIMPLE_LOG")) begin

                $display(
                    ".scoreboard     [SCB] F%0d XY : EXP Stick=(%0d,%0d) Hand=(%0d,%0d) | ACT Stick=(%0d,%0d) Hand=(%0d,%0d)",
                    exp.frame_id, exp.exp_stick_x, exp.exp_stick_y, exp.exp_hand_x,
                    exp.exp_hand_y, act.act_stick_x, act.act_stick_y, act.act_hand_x,
                    act.act_hand_y);

                $display(
                    ".scoreboard     [SCB] F%0d PAYLOAD : EXP=0x%010h | ACT=0x%010h",
                    exp.frame_id, exp.exp_o_pixel, act.act_o_pixel);

                $display(
                    ".scoreboard     [SCB] F%0d TIMING : S->V=%0dclk V->VALID=%0dclk READY_DLY=%0dclk HS=%0dclk",
                    exp.frame_id, sentinel_to_vsync, vsync_to_valid, exp.ready_delay,
                    valid_to_handshake);

                $display(".scoreboard     [SCB] F%0d RESULT : PASS", exp.frame_id);

            end
            if ($test$plusargs("SHOW_SCOREBOARD")) begin

                $display("");
                $display(
                    "====================================================================");
                $display("                 RG_DETECT SCOREBOARD RESULT");
                $display(
                    "====================================================================");
                $display(" Frame ID      : %0d", exp.frame_id);
                $display(" Object State  : %s", object_name(exp.red_en, exp.green_en));
                $display(
                    "--------------------------------------------------------------------");

                $display(" [ XY COORDINATE ]");
                $display(" EXPECTED Stick : (%0d, %0d)", exp.exp_stick_x, exp.exp_stick_y);

                $display(" ACTUAL   Stick : (%0d, %0d)", act.act_stick_x, act.act_stick_y);

                $display(" EXPECTED Hand  : (%0d, %0d)", exp.exp_hand_x, exp.exp_hand_y);

                $display(" ACTUAL   Hand  : (%0d, %0d)", act.act_hand_x, act.act_hand_y);

                $display(
                    "--------------------------------------------------------------------");

                $display(" [ UART PAYLOAD ]");
                $display(" EXPECTED o_pixel : 0x%010h", exp.exp_o_pixel);

                $display(" ACTUAL   o_pixel : 0x%010h", act.act_o_pixel);

                $display(
                    "--------------------------------------------------------------------");

                $display(" [ FRAME / HANDSHAKE TIMING ]");
                $display(" FrameEnd -> VSYNC : %0d clk", sentinel_to_vsync);

                $display(" VSYNC    -> VALID : %0d clk", vsync_to_valid);

                $display(" READY Delay       : %0d clk", exp.ready_delay);

                $display(" VALID -> Handshake: %0d clk", valid_to_handshake);

                $display(" Payload Stable    : %s", act.payload_stable ? "PASS" : "FAIL");

                $display(
                    "--------------------------------------------------------------------");
                $display(" RESULT             : PASS");
                $display(
                    "====================================================================");
                $display("");

            end


            `uvm_info("RG_DETECT_PASS", $sformatf("[F%0d] %s PASS", exp.frame_id, object_name(
                                                  exp.red_en, exp.green_en)), UVM_LOW)

        end else begin

            error_count++;

            `uvm_error("RG_DETECT_FAIL", $sformatf(
                       "[F%0d] FAIL | coord=%0b uart_pack=%0b frame_timing=%0b handshake=%0b stable=%0b | S->V=%0dclk V->VALID=%0dclk HS=%0dclk | EXP Stick=(%0d,%0d) Hand=(%0d,%0d) ACT Stick=(%0d,%0d) Hand=(%0d,%0d)",
                       exp.frame_id,
                       coord_ok,
                       uart_pack_ok,
                       frame_timing_ok,
                       handshake_ok,
                       act.payload_stable,
                       sentinel_to_vsync,
                       vsync_to_valid,
                       valid_to_handshake,
                       exp.exp_stick_x,
                       exp.exp_stick_y,
                       exp.exp_hand_x,
                       exp.exp_hand_y,
                       act.act_stick_x,
                       act.act_stick_y,
                       act.act_hand_x,
                       act.act_hand_y
                       ))

        end

    endfunction


    function void check_phase(uvm_phase phase);

        super.check_phase(phase);

        if (expected_q.size() != 0) begin
            `uvm_error("EXPECTED_LEFT", $sformatf("%0d expected frame(s) left",
                                                  expected_q.size()))
        end

        if (actual_q.size() != 0) begin
            `uvm_error("ACTUAL_LEFT", $sformatf("%0d actual frame(s) left", actual_q.size()))
        end

    endfunction


    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info("RG_DETECT_SUMMARY", $sformatf(
                  "RG_detect VERIFICATION RESULT | Compared=%0d Pass=%0d Errors=%0d | BOTH=%0d RED_ONLY=%0d GREEN_ONLY=%0d | READY Immediate=%0d Delayed=%0d | Functional Coverage=%.1f%% | Checked: RED/GREEN + XY + FRAME END + UART o_pixel + VALID/READY",
                  compared_count,
                  pass_count,
                  error_count,
                  both_count,
                  red_only_count,
                  green_only_count,
                  immediate_count,
                  delayed_count,
                  rg_detect_cg.get_inst_coverage()
                  ), UVM_LOW)
        if ($test$plusargs("SIMPLE_LOG")) begin

            $display(".scoreboard     [SCB] SUMMARY : Total=%0d PASS=%0d FAIL=%0d",
                     compared_count, pass_count, error_count);

        end
    endfunction

endclass

