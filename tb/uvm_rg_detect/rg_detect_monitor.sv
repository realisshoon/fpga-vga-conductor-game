class rg_detect_monitor extends uvm_monitor;

    `uvm_component_utils(rg_detect_monitor)

    virtual rg_detect_if vif;

    uvm_analysis_port #(rg_detect_item) actual_ap;

    longint unsigned cycle_count;
    longint unsigned sentinel_cycle;
    longint unsigned vsync_cycle;
    longint unsigned valid_cycle;

    int unsigned next_frame_id;
    int unsigned active_frame_id;

    bit valid_prev;
    bit vsync_seen;
    bit payload_stable;

    logic [9:0] hold_stick_x;
    logic [9:0] hold_stick_y;
    logic [9:0] hold_hand_x;
    logic [9:0] hold_hand_y;
    logic [39:0] hold_o_pixel;


    function new(string name = "rg_detect_monitor", uvm_component parent = null);
        super.new(name, parent);
        actual_ap = new("actual_ap", this);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual rg_detect_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "rg_detect_if not found")
        end

    endfunction


    task run_phase(uvm_phase phase);

        rg_detect_item tr;

        cycle_count   = 0;
        next_frame_id = 0;
        valid_prev    = 0;
        vsync_seen    = 0;

        forever begin

            @(vif.mon_cb);
            cycle_count++;

            if (vif.mon_cb.rst) begin
                valid_prev = 0;
                vsync_seen = 0;
            end else begin

                // Capture the frame-end sentinel cycle.
                if (
(vif.mon_cb.i_x_pixel == 10'd320) &&
(vif.mon_cb.i_y_pixel == 10'd239)
) begin

                    sentinel_cycle = cycle_count;

                    if ($test$plusargs("SIMPLE_LOG")) begin
                        $display(".agent.monitor  [MON] F%0d FRAME_END : x=320 y=239",
                                 next_frame_id);
                    end

                end


                // Capture o_vsync and updated coordinates.
                if (vif.mon_cb.o_vsync) begin

                    active_frame_id = next_frame_id;
                    next_frame_id++;

                    vsync_seen  = 1'b1;
                    vsync_cycle = cycle_count;

                    if ($test$plusargs("SIMPLE_LOG")) begin
                        $display(
                            ".agent.monitor  [MON] F%0d RESULT : VSYNC=1 Stick=(%0d,%0d) Hand=(%0d,%0d)",
                            active_frame_id, vif.mon_cb.o_stick_x_pixel,
                            vif.mon_cb.o_stick_y_pixel, vif.mon_cb.o_hand_x_pixel,
                            vif.mon_cb.o_hand_y_pixel);
                    end

                end

                // Capture the VALID rising edge.
                if (vif.mon_cb.xy_control_valid && !valid_prev) begin

                    valid_cycle = cycle_count;
                    payload_stable = 1'b1;

                    hold_stick_x = vif.mon_cb.o_stick_x_pixel;
                    hold_stick_y = vif.mon_cb.o_stick_y_pixel;
                    hold_hand_x = vif.mon_cb.o_hand_x_pixel;
                    hold_hand_y = vif.mon_cb.o_hand_y_pixel;
                    hold_o_pixel = vif.mon_cb.o_pixel;
                    if ($test$plusargs("SIMPLE_LOG")) begin
                        $display(".agent.monitor  [MON] F%0d VALID : valid=1 ready=%0b",
                                 active_frame_id, vif.mon_cb.xy_control_ready);
                    end
                end


                // Payload must remain stable while VALID=1 and READY=0.
                if (vif.mon_cb.xy_control_valid && !vif.mon_cb.xy_control_ready) begin

                    if (
                        (vif.mon_cb.o_stick_x_pixel !== hold_stick_x) ||
                        (vif.mon_cb.o_stick_y_pixel !== hold_stick_y) ||
                        (vif.mon_cb.o_hand_x_pixel  !== hold_hand_x ) ||
                        (vif.mon_cb.o_hand_y_pixel  !== hold_hand_y ) ||
                        (vif.mon_cb.o_pixel         !== hold_o_pixel)
                    ) begin
                        payload_stable = 1'b0;
                    end

                end


                // VALID && READY completes the transfer.
                if (
                    vif.mon_cb.xy_control_valid &&
                    vif.mon_cb.xy_control_ready &&
                    vsync_seen
                ) begin

                    tr = rg_detect_item::type_id::create($sformatf("act_%0d", active_frame_id));

                    tr.frame_id = active_frame_id;

                    tr.act_stick_x = vif.mon_cb.o_stick_x_pixel;
                    tr.act_stick_y = vif.mon_cb.o_stick_y_pixel;
                    tr.act_hand_x = vif.mon_cb.o_hand_x_pixel;
                    tr.act_hand_y = vif.mon_cb.o_hand_y_pixel;
                    tr.act_o_pixel = vif.mon_cb.o_pixel;

                    tr.vsync_seen = 1'b1;
                    tr.valid_seen = 1'b1;
                    tr.handshake_seen = 1'b1;
                    tr.payload_stable = payload_stable;

                    tr.sentinel_cycle = sentinel_cycle;
                    tr.vsync_cycle = vsync_cycle;
                    tr.valid_cycle = valid_cycle;
                    tr.handshake_cycle = cycle_count;

                    actual_ap.write(tr);

                    vsync_seen = 1'b0;

                end

                valid_prev = vif.mon_cb.xy_control_valid;

            end

        end

    endtask

endclass

