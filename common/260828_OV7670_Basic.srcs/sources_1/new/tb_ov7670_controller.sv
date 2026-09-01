`timescale 1ns / 1ps

module tb_ov7670_controller ();

    logic clk;
    logic rst;
    logic scl;
    wire  sda;

    pullup (sda);

    SCCB_Setup_controller dut (
        .clk(clk),
        .rst(rst),
        .scl(scl),
        .sda(sda)
    );
    logic [7:0] rx_data;
    logic [7:0] golden  [0:117];

    initial begin
        $readmemh("ov7670_setup_rom.mem", golden);
    end

    int i, j;
    int transfer;
    int addr;
    int pass, fail;

    task ov7670();
        for (transfer = 0; transfer < 59; transfer++) begin
            // OV7670 ADDR
            repeat (9) @(posedge scl);

            // data sampling
            for (j = 0; j < 2; j++) begin
                addr = 2 * transfer + j;
                for (i = 0; i < 8; i++) begin
                    @(posedge scl);
                    rx_data <= {rx_data[6:0], sda};
                end
                @(posedge scl);  // wait for ack
                // PASS/FAIL
                if (rx_data == golden[addr]) begin
                    pass++;
                    $display("[%0t]: PASS, rx_data = %h, golden[%2d] = %h",
                             $time, rx_data, addr, golden[addr]);
                end else begin
                    fail++;
                    $display("[%0t]: FAIL, rx_data = %h, golden[%2d] = %h",
                             $time, rx_data, addr, golden[addr]);
                end
            end
            @(posedge scl);
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;

        ov7670();

        $display("-------------- Total PASS, FAIL ---------------");
        $display("-------------- PASS: %3d ---------------", pass);
        $display("-------------- FAIL: %3d ---------------", fail);
        $display("-----------------------------------------------");

        $finish;
    end

endmodule
