class rg_detect_driver extends uvm_driver #(rg_detect_item);

    `uvm_component_utils(rg_detect_driver)

    virtual rg_detect_if vif;

    uvm_analysis_port #(rg_detect_item) expected_ap;


    function new(string name = "rg_detect_driver", uvm_component parent = null);
        super.new(name, parent);
        expected_ap = new("expected_ap", this);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual rg_detect_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "rg_detect_if not found")
        end

    endfunction


    function logic [11:0] pixel_rgb(rg_detect_item req, int x, int y);

        if (
            req.red_en &&
            (x >= req.red_x_min) &&
            (x <= req.red_x_max) &&
            (y >= req.red_y_min) &&
            (y <= req.red_y_max)
        ) begin
            return req.red_rgb;
        end

        if (
            req.green_en &&
            (x >= req.green_x_min) &&
            (x <= req.green_x_max) &&
            (y >= req.green_y_min) &&
            (y <= req.green_y_max)
        ) begin
            return req.green_rgb;
        end

        return req.bg_rgb;

    endfunction


    task drive_frame(rg_detect_item req);

        rg_detect_item exp;

        exp = rg_detect_item::type_id::create($sformatf("exp_%0d", req.frame_id));

        exp.copy(req);
        exp.calc_expected();
        expected_ap.write(exp);

        if ($test$plusargs("SIMPLE_LOG")) begin
            $display(".agent.driver   [DRV] F%0d INPUT : RED=%0b GREEN=%0b READY_DLY=%0d",
                     req.frame_id, req.red_en, req.green_en, req.ready_delay);
        end
        @(vif.drv_cb);

        if (req.ready_delay == 0) vif.drv_cb.xy_control_ready <= 1'b1;
        else vif.drv_cb.xy_control_ready <= 1'b0;


        // Drive one 320 x 240 active frame.
        for (int y = 0; y < 240; y++) begin
            for (int x = 0; x < 320; x++) begin

                @(vif.drv_cb);

                vif.drv_cb.i_x_pixel <= x;
                vif.drv_cb.i_y_pixel <= y;
                vif.drv_cb.i_rgb     <= pixel_rgb(req, x, y);
                vif.drv_cb.de        <= 1'b1;

            end
        end


        // Frame End sentinel = (320,239)
        @(vif.drv_cb);

        vif.drv_cb.i_x_pixel <= 10'd320;
        vif.drv_cb.i_y_pixel <= 10'd239;
        vif.drv_cb.i_rgb     <= 12'h000;
        vif.drv_cb.de        <= 1'b0;


        // Return to idle one cycle after the sentinel.
        @(vif.drv_cb);

        vif.drv_cb.i_x_pixel <= 10'd0;
        vif.drv_cb.i_y_pixel <= 10'd0;
        vif.drv_cb.i_rgb     <= 12'h000;
        vif.drv_cb.de        <= 1'b0;


        // VALID 발생 대기
        while (!vif.drv_cb.xy_control_valid) @(vif.drv_cb);


        // Assert delayed READY after a posedge so VALID remains visible at the next negedge sample.
        if (req.ready_delay > 0) begin

            repeat (req.ready_delay) @(posedge vif.clk);

            vif.xy_control_ready <= 1'b1;

        end


        // Allow handshake sampling and DUT VALID deassertion.
        @(vif.drv_cb);
        @(vif.drv_cb);

    endtask


    task run_phase(uvm_phase phase);

        rg_detect_item req;

        wait (vif.rst == 1'b0);

        forever begin

            seq_item_port.get_next_item(req);

            drive_frame(req);

            seq_item_port.item_done();

        end

    endtask

endclass

