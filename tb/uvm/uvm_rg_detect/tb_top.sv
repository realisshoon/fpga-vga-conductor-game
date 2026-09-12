module tb_top;

    import uvm_pkg::*;
    import rg_detect_pkg::*;

    logic clk;

    rg_detect_if vif (.clk(clk));


    RG_detect DUT (
        .clk             (clk),
        .rst             (vif.rst),
        .i_rgb           (vif.i_rgb),
        .i_x_pixel       (vif.i_x_pixel),
        .i_y_pixel       (vif.i_y_pixel),
        .de              (vif.de),
        .xy_control_ready(vif.xy_control_ready),
        .o_stick_x_pixel (vif.o_stick_x_pixel),
        .o_stick_y_pixel (vif.o_stick_y_pixel),
        .o_hand_x_pixel  (vif.o_hand_x_pixel),
        .o_hand_y_pixel  (vif.o_hand_y_pixel),
        .o_vsync         (vif.o_vsync),
        .o_pixel         (vif.o_pixel),
        .xy_control_valid(vif.xy_control_valid)
    );


    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    initial begin

        vif.rst              = 1'b1;
        vif.i_rgb            = 12'h000;
        vif.i_x_pixel        = 10'd0;
        vif.i_y_pixel        = 10'd0;
        vif.de               = 1'b0;
        vif.xy_control_ready = 1'b0;

        repeat (5) @(posedge clk);

        @(negedge clk);
        vif.rst = 1'b0;

    end


    initial begin

        uvm_config_db#(virtual rg_detect_if)::set(null, "*", "vif", vif);

        run_test();

    end

        // Capture 18 frames to cover all object states and READY delays 0-5.
        // Regression 전체를 FSDB로 저장하면 파일이 매우 커질 수 있으므로
        // 대표 18 Frame만 파형 저장.
        // 첫 18 Frame 안에 BOTH/RED/GREEN 및 READY delay 0~5가 모두 포함된다.
        $fsdbDumpfile("rg_detect_uvm.fsdb");
        $fsdbDumpvars(0, tb_top);

        repeat (18 * 76840) @(posedge clk);

        $fsdbDumpoff;

    end

endmodule

