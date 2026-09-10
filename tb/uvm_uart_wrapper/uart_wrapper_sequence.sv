class uart_wrapper_random_sequence extends uvm_sequence #(uart_wrapper_seq_item);
    `uvm_object_utils(uart_wrapper_random_sequence)

    int unsigned num_frames = 10;

    function new(string name = "uart_wrapper_sequence");
        super.new(name);
    endfunction

    task body();
        repeat (num_frames) begin
            req = uart_wrapper_seq_item::type_id::create("req");

            start_item(req);
            assert (req.randomize())
            else `uvm_fatal("SEQ", "Randomization failed")

            finish_item(req);
        end
    endtask
endclass

class uart_wrapper_rx_pattern_sequence extends uvm_sequence #(uart_wrapper_seq_item);
    `uvm_object_utils(uart_wrapper_rx_pattern_sequence)

    function new(string name = "uart_wrapper_rx_pattern_sequence");
        super.new(name);
    endfunction

    task body();
            bit [7:0] patterns[4] = '{8'h00, 8'h55, 8'hAA, 8'hFF};

            foreach(patterns[i]) begin
                req = uart_wrapper_seq_item::type_id::create("req");

                start_item(req);
                req.expected_rx_data = patterns[i];
                finish_item(req);
            end
    endtask
endclass

class uart_wrapper_tx_field_sequence extends uvm_sequence #(uart_wrapper_seq_item);
    `uvm_object_utils(uart_wrapper_tx_field_sequence)

    function new(string name = "uart_wrapper_tx_field_sequence");
        super.new(name);
    endfunction

    task body();
        bit [5:0] enable_mask;

        // 2개 전체 조합 + 6개 field × 최솟값/최댓값 = 14프레임
        for (int i = 0; i < 14; i++) begin
            req = uart_wrapper_seq_item::type_id::create("req");
            start_item(req);

            if (!req.randomize())
                `uvm_fatal("SEQ", "Randomization failed")

            if (i == 0)
                enable_mask = 6'b111111;  // 전체 ON
            else if (i == 1)
                enable_mask = 6'b000000;  // 전체 OFF: 이전 값 유지
            else
                enable_mask = 6'b000001 << ((i - 2) / 2);

            {
                req.pattern_state_enable,
                req.game_state_enable,
                req.score_enable,
                req.speed_enable,
                req.pixel_enable,
                req.volume_enable
            } = enable_mask;

            // 이 시나리오는 field 선택과 값 검증에 집중
            req.volume_delay        = 0;
            req.pixel_delay         = 0;
            req.speed_delay         = 0;
            req.score_delay         = 0;
            req.game_state_delay    = 0;
            req.pattern_state_delay = 0;

            // 첫 프레임은 모두 최댓값.
            // 이후 각 field를 최솟값 → 최댓값 순으로 전송.
            if (i == 0 || (i >= 2 && i % 2 == 1)) begin
                req.i_volume_level  = '1;
                req.i_pixel         = '1;
                req.i_speed         = '1;
                req.i_score         = '1;
                req.i_game_state    = '1;
                req.i_pattern_state = '1;
            end else begin
                req.i_volume_level  = '0;
                req.i_pixel         = '0;
                req.i_speed         = '0;
                req.i_score         = '0;
                req.i_game_state    = '0;
                req.i_pattern_state = '0;
            end

            finish_item(req);
        end
    endtask
endclass

// Cover every pair of the seven byte categories at every adjacent position.
class uart_wrapper_tx_byte_pair_sequence extends uvm_sequence #(uart_wrapper_seq_item);
    `uvm_object_utils(uart_wrapper_tx_byte_pair_sequence)

    function new(string name = "uart_wrapper_tx_byte_pair_sequence");
        super.new(name);
    endfunction

    task body();
        bit [7:0] values[7] = '{8'h00, 8'h20, 8'h55, 8'h80,
                               8'hAA, 8'hD0, 8'hFF};
        bit [63:0] data;
        foreach (values[a]) begin
            foreach (values[b]) begin
                // LSB-first byte order is A B A B A B A B.
                data = {4{values[b], values[a]}};
                req = uart_wrapper_seq_item::type_id::create("req");
                start_item(req);
                {req.pattern_state_enable, req.game_state_enable,
                 req.score_enable, req.speed_enable,
                 req.pixel_enable, req.volume_enable} = '1;
                req.volume_delay = 0;
                req.pixel_delay = 0;
                req.speed_delay = 0;
                req.score_delay = 0;
                req.game_state_delay = 0;
                req.pattern_state_delay = 0;
                req.i_score = data[3:0];
                req.i_speed = data[11:4];
                req.i_volume_level = data[18:12];
                req.i_pattern_state = data[21:19];
                req.i_pixel = data[61:22];
                req.i_game_state = data[63:62];
                finish_item(req);
            end
        end
    endtask
endclass
