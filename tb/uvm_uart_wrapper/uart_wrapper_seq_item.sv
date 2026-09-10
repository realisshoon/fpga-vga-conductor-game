class uart_wrapper_seq_item extends uvm_sequence_item;
    `uvm_object_utils(uart_wrapper_seq_item)

    // tx driving source
    rand logic [6:0] i_volume_level;
    rand logic [39:0] i_pixel;
    rand logic [7:0] i_speed;
    rand logic [3:0] i_score;
    rand logic [1:0] i_game_state;
    rand logic [2:0] i_pattern_state;

    rand logic [3:0] volume_delay;
    rand logic [3:0] pixel_delay;
    rand logic [3:0] speed_delay;
    rand logic [3:0] score_delay;
    rand logic [3:0] game_state_delay;
    rand logic [3:0] pattern_state_delay;

    // if enable -> drive
    rand bit volume_enable;
    rand bit pixel_enable;
    rand bit speed_enable;
    rand bit score_enable;
    rand bit game_state_enable;
    rand bit pattern_state_enable;

    // Observed handshakes in the current TX frame; not sequence enables.
    bit volume_hs;
    bit pixel_hs;
    bit speed_hs;
    bit score_hs;
    bit game_state_hs;
    bit pattern_state_hs;

    // rx
    bit [7:0] o_rx_data;

    // to scoerboard
    rand logic [7:0] expected_rx_data;  // driving
    bit rx_comp;
    bit overlap_seen;  // Monitor observed overlapping TX/RX byte frames.

    bit tx_comp;  // 스코어보드에서 비교하라는 flag
    logic [63:0] expected_tx_data;  // handshake를 감시하며 채워넣기
    logic [63:0] actual_tx_data; // tx desirializer를 moniotr에서 구축하기. sampling하면 flag와 함께 채워넣기
    // field macro는 다음에 사용하도록.... 하자
    //`uvm_object_utils_begin(uart_wrapper_seq_item)
    //    `uvm_field_int(i_volume_level, UVM_DEFAULT)
    //    `uvm_field_int(i_pixel, UVM_DEFAULT)
    //    `uvm_field_int(i_speed, UVM_DEFAULT)
    //    `uvm_field_int(i_score, UVM_DEFAULT)
    //    `uvm_field_int(i_game_state, UVM_DEFAULT)
    //    `uvm_field_int(i_patter_state, UVM_DEFAULT)

    //    `uvm_field_int(volume_dealy, UVM_DEFAULT | UVM_NOCOMPARE)
    //    `uvm_field_int(pixel_dealy, UVM_DEFAULT | UVM_NOCOMPARE)
    //    `uvm_field_int(speed_dealy, UVM_DEFAULT | UVM_NOCOMPARE)
    //    `uvm_field_int(score_dealy, UVM_DEFAULT | UVM_NOCOMPARE)
    //    `uvm_field_int(game_state_dealy, UVM_DEFAULT | UVM_NOCOMPARE)
    //    `uvm_field_int(pattern_state_dealy, UVM_DEFAULT | UVM_NOCOMPARE)

    //    `uvm_field_int(o_rx_data, UVM_DEFAULT)
    //`uvm_object_utils_end

    function new(string name = "uart_wrapper_seq_item");
        super.new(name);
    endfunction

endclass

