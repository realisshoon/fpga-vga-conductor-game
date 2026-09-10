class rg_detect_item extends uvm_sequence_item;

    int unsigned frame_id;

    bit red_en;
    bit green_en;

    logic [11:0] red_rgb;
    logic [11:0] green_rgb;
    logic [11:0] bg_rgb;

    int red_x_min;
    int red_x_max;
    int red_y_min;
    int red_y_max;

    int green_x_min;
    int green_x_max;
    int green_y_min;
    int green_y_max;

    int unsigned ready_delay;

    logic [9:0] exp_stick_x;
    logic [9:0] exp_stick_y;
    logic [9:0] exp_hand_x;
    logic [9:0] exp_hand_y;
    logic [39:0] exp_o_pixel;

    logic [9:0] act_stick_x;
    logic [9:0] act_stick_y;
    logic [9:0] act_hand_x;
    logic [9:0] act_hand_y;
    logic [39:0] act_o_pixel;

    bit vsync_seen;
    bit valid_seen;
    bit handshake_seen;
    bit payload_stable;

    longint unsigned sentinel_cycle;
    longint unsigned vsync_cycle;
    longint unsigned valid_cycle;
    longint unsigned handshake_cycle;


    `uvm_object_utils_begin(rg_detect_item)
        `uvm_field_int(frame_id, UVM_ALL_ON)
        `uvm_field_int(red_en, UVM_ALL_ON)
        `uvm_field_int(green_en, UVM_ALL_ON)
        `uvm_field_int(red_rgb, UVM_ALL_ON)
        `uvm_field_int(green_rgb, UVM_ALL_ON)
        `uvm_field_int(bg_rgb, UVM_ALL_ON)
        `uvm_field_int(red_x_min, UVM_ALL_ON)
        `uvm_field_int(red_x_max, UVM_ALL_ON)
        `uvm_field_int(red_y_min, UVM_ALL_ON)
        `uvm_field_int(red_y_max, UVM_ALL_ON)
        `uvm_field_int(green_x_min, UVM_ALL_ON)
        `uvm_field_int(green_x_max, UVM_ALL_ON)
        `uvm_field_int(green_y_min, UVM_ALL_ON)
        `uvm_field_int(green_y_max, UVM_ALL_ON)
        `uvm_field_int(ready_delay, UVM_ALL_ON)
        `uvm_field_int(exp_stick_x, UVM_ALL_ON)
        `uvm_field_int(exp_stick_y, UVM_ALL_ON)
        `uvm_field_int(exp_hand_x, UVM_ALL_ON)
        `uvm_field_int(exp_hand_y, UVM_ALL_ON)
        `uvm_field_int(exp_o_pixel, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "rg_detect_item");
        super.new(name);
    endfunction


    function void calc_expected();

        if (red_en) begin
            exp_stick_x = red_x_min + ((red_x_max - red_x_min) >> 1);
            exp_stick_y = red_y_min + ((red_y_max - red_y_min) >> 1);
        end else begin
            exp_stick_x = 10'd1023;
            exp_stick_y = 10'd1023;
        end

        if (green_en) begin
            exp_hand_x = green_x_min + ((green_x_max - green_x_min) >> 1);
            exp_hand_y = green_y_min + ((green_y_max - green_y_min) >> 1);
        end else begin
            exp_hand_x = 10'd1023;
            exp_hand_y = 10'd1023;
        end

        exp_o_pixel = {exp_stick_x, exp_stick_y, exp_hand_x, exp_hand_y};

    endfunction

endclass

