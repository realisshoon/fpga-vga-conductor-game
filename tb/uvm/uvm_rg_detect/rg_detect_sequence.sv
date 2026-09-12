class rg_detect_sequence extends uvm_sequence #(rg_detect_item);

    `uvm_object_utils(rg_detect_sequence)

    function new(string name = "rg_detect_sequence");
        super.new(name);
    endfunction


    task body();

        rg_detect_item req;

        int unsigned num_frames;

        int red_cx;
        int red_cy;
        int red_half;

        int green_cx;
        int green_cy;
        int green_half;


        if (!$value$plusargs("NUM_FRAMES=%d", num_frames)) num_frames = 100;


        `uvm_info("RG_DETECT_SEQ",
                  $sformatf(
                      "Generating %0d frames : object/position/size/READY-delay variation",
                      num_frames), UVM_LOW)


        for (int i = 0; i < num_frames; i++) begin

            req = rg_detect_item::type_id::create($sformatf("req_%0d", i));

            start_item(req);

            req.frame_id    = i;

            req.red_rgb     = 12'hF00;
            req.green_rgb   = 12'h0F0;
            req.bg_rgb      = 12'h000;

            // Exercise READY delays 0-5 for every object state.
            req.ready_delay = (i / 3) % 6;

            red_half        = 6 + (i % 5);  // 6 ~ 10
            green_half      = 6 + ((i + 2) % 5);  // 6 ~ 10

            req.red_en      = 1'b0;
            req.green_en    = 1'b0;

            req.red_x_min   = 0;
            req.red_x_max   = 0;
            req.red_y_min   = 0;
            req.red_y_max   = 0;

            req.green_x_min = 0;
            req.green_x_max = 0;
            req.green_y_min = 0;
            req.green_y_max = 0;


            case (i % 3)

                // Keep red and green regions separated in BOTH frames.
                0: begin

                    req.red_en = 1'b1;
                    req.green_en = 1'b1;

                    red_cx = 170 + ((i * 17) % 130);  // 170 ~ 299
                    red_cy = 15 + ((i * 13) % 210);  // 15  ~ 224

                    green_cx = 20 + ((i * 11) % 120);  // 20  ~ 139
                    green_cy = 15 + ((i * 7) % 210);  // 15  ~ 224

                    req.red_x_min = red_cx - red_half;
                    req.red_x_max = red_cx + red_half;
                    req.red_y_min = red_cy - red_half;
                    req.red_y_max = red_cy + red_half;

                    req.green_x_min = green_cx - green_half;
                    req.green_x_max = green_cx + green_half;
                    req.green_y_min = green_cy - green_half;
                    req.green_y_max = green_cy + green_half;

                end


                1: begin

                    req.red_en = 1'b1;
                    req.green_en = 1'b0;

                    red_cx = 15 + ((i * 17) % 290);  // 15 ~ 304
                    red_cy = 15 + ((i * 13) % 210);  // 15 ~ 224

                    req.red_x_min = red_cx - red_half;
                    req.red_x_max = red_cx + red_half;
                    req.red_y_min = red_cy - red_half;
                    req.red_y_max = red_cy + red_half;

                end


                default: begin

                    req.red_en = 1'b0;
                    req.green_en = 1'b1;

                    green_cx = 15 + ((i * 19) % 290);  // 15 ~ 304
                    green_cy = 15 + ((i * 11) % 210);  // 15 ~ 224

                    req.green_x_min = green_cx - green_half;
                    req.green_x_max = green_cx + green_half;
                    req.green_y_min = green_cy - green_half;
                    req.green_y_max = green_cy + green_half;

                end

            endcase


            req.calc_expected();

            finish_item(req);

        end

    endtask

endclass

