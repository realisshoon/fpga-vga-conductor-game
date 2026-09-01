`timescale 1ns / 1ps

module SCCB_Setup_controller (
    input  logic clk,
    input  logic rst,
    // external i2c port
    output logic scl,
    inout  wire  sda
);
    logic cmd_start, cmd_write, cmd_read, cmd_stop;
    logic [7:0] tx_data, rx_data;
    logic ack_in, ack_out;
    logic busy, done;

    ov7670_setup_fsm U_FSM (
        .clk(clk),
        .rst(rst),
        // to i2c master
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .ack_in   (ack_in),

        // from i2c master
        .rx_data(rx_data),
        .ack_out(ack_out),
        .busy   (busy),
        .done   (done)
    );

    i2c_master_top U_I2C (
        .clk(clk),
        .rst(rst),

        // from fsm
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        .tx_data(tx_data),
        .ack_in(ack_in),

        // to fsm
        .rx_data(rx_data),
        .ack_out(ack_out),
        .busy   (busy),
        .done   (done),

        // to ov7670
        .scl(scl),
        .sda(sda)
    );

endmodule

module ov7670_setup_fsm (
    // global signal
    input  logic       clk,
    input  logic       rst,
    // to i2c master 
    output logic       cmd_start,
    output logic       cmd_write,
    output logic       cmd_read,
    output logic       cmd_stop,
    output logic [7:0] tx_data,
    output logic       ack_in,
    // from i2c master
    input  logic       ack_out,
    input  logic [7:0] rx_data,
    input  logic       busy,
    input  logic       done
);
    // OV7670 address
    localparam OV7670_ADDR = 7'h21;
    // setup ROM
    logic [7:0] addr, n_addr;
    logic [7:0] mem[0:117];  // ov7670 setup data ROM
    initial begin
        $readmemh("ov7670_setup_rom.mem", mem);
    end

    typedef enum logic [2:0] {
        IDLE = 3'd0,
        RESET,
        WAIT_30,
        DEFAULT,
        WAIT,
        QVGA_RGB,
        STOP
    } state_e;

    state_e c_state, n_state;
    // i2c command & data
    logic n_cmd_start;
    logic n_cmd_write;
    logic n_cmd_read;
    logic n_cmd_stop;
    logic n_ack_in;

    // byte transfer # in i2c
    logic [1:0] phase, n_phase;
    assign tx_data = (phase == 1) ? {OV7670_ADDR, 1'b0} : mem[addr];

    // transfer # of OV7670 setup data;
    logic [5:0] transfer, n_transfer;

    // wait duration generator
    logic wait_start, delay;
    logic tick, wait_done;
    logic [ 9:0] psc;
    logic [12:0] cnt;
    logic [12:0] target_r, target;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick      <= 1'b0;
            wait_done <= 1'b0;
            psc       <= 0;
            cnt       <= 0;
            target_r  <= 0;
            delay     <= 0;
        end else begin
            if (wait_start) begin
                target_r <= target;
                if (psc == 1_000 - 1) begin
                    tick <= 1'b1;
                    psc  <= 0;
                end else begin
                    tick <= 1'b0;
                    psc  <= psc + 1;
                end
                if (tick) begin
                    if (cnt == target_r - 1) begin
                        wait_done <= 1'b1;
                        delay <= 1'b0;
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end
            end else begin
                tick      <= 1'b0;
                wait_done <= 1'b0;
                psc       <= 0;
                cnt       <= 0;
                target_r  <= 0;
            end
        end
    end

    // current state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state   <= IDLE;
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;
            ack_in    <= 0;
            addr      <= 0;
            transfer  <= 0;
            phase     <= 0;
        end else begin
            cmd_start <= n_cmd_start;
            cmd_write <= n_cmd_write;
            cmd_read  <= n_cmd_read;
            cmd_stop  <= n_cmd_stop;
            ack_in    <= n_ack_in;
            c_state   <= n_state;
            addr      <= n_addr;
            transfer  <= n_transfer;
            phase     <= n_phase;
        end
    end

    // next state CL
    always @(*) begin
        n_state = c_state;
        case (c_state)
            IDLE: n_state = RESET;
            RESET: if (transfer == 1) n_state = WAIT_30;
            WAIT_30: if (wait_done) n_state = DEFAULT;
            DEFAULT: begin
                if (wait_start) n_state = WAIT;
            end
            WAIT: begin
                if (wait_done) begin
                    if (transfer == 42) n_state = QVGA_RGB;
                    else n_state = DEFAULT;
                end
            end
            QVGA_RGB: if (transfer == 16) n_state = STOP;
            STOP: n_state = STOP;
            default: n_state = c_state;
        endcase
    end

    // output CL
    always @(*) begin
        n_cmd_start = cmd_start;
        n_cmd_write = cmd_write;
        n_cmd_read  = cmd_read;
        n_cmd_stop  = cmd_stop;
        n_ack_in    = ack_in;
        n_addr      = addr;
        n_transfer  = transfer;
        n_phase     = phase;
        target      = target_r;
        wait_start  = 0;
        case (c_state)
            IDLE: begin
                n_cmd_start = 1'b1;
            end
            RESET: begin
                n_cmd_start = 1'b0;
                n_cmd_write = 1'b0;
                if (done && busy) begin // done cycle에만 출력됨. 1 cycle의 조합출력 -> registering
                    // done && busy -> stop condition이다.
                    n_phase = phase + 1;
                    n_cmd_write = 1'b1;
                    case (phase)
                        2'd0: begin
                            // start완료 시 done, data 전송 없음
                            // flag로 동작
                            // OV7670 주소 전송 명령
                        end
                        2'd1: begin
                            // register 주소 전송 명령
                        end
                        2'd2: begin
                            // data 전송 명령
                            // 다음 rom 주소로 업데이트
                            n_addr = addr + 1;
                        end
                        2'd3: begin
                            // 전송 완료
                            n_phase     = 0;
                            n_cmd_start = 1'b0;
                            n_cmd_write = 1'b0;
                            n_cmd_stop  = 1'b1;
                            n_addr      = addr + 1;
                            n_transfer  = transfer + 1;
                        end
                        default: begin
                            n_phase = phase + 1;
                            n_cmd_write = 1'b1;
                        end
                    endcase
                end
            end
            WAIT_30: begin
                wait_start = 1'b1;
                target = 3000;
                n_cmd_stop = 1'b0;
                if (wait_done) begin
                    n_transfer  = 0;
                    n_cmd_start = 1'b1;
                end
            end
            DEFAULT: begin
                if (transfer == 42) begin
                    n_cmd_start = 1'b0;
                    n_cmd_write = 1'b0;
                end else begin
                    n_cmd_start = 1'b0;
                    n_cmd_write = 1'b0;
                    if (done && busy) begin // done cycle에만 출력됨. 1 cycle의 조합출력 -> registering
                        n_phase = phase + 1;
                        n_cmd_write = 1'b1;
                        case (phase)
                            2'd0: begin
                                // start완료 시 done, data 전송 없음
                                // flag로 동작
                                // OV7670 주소 전송 명령
                            end
                            2'd1: begin
                                // register 주소 전송 명령
                            end
                            2'd2: begin
                                // data 전송 명령
                                // 다음 rom 주소로 업데이트
                                n_addr = addr + 1;
                            end
                            2'd3: begin
                                // 전송 완료
                                n_cmd_start = 1'b0;
                                n_cmd_write = 1'b0;
                                wait_start  = 1'b1;
                                n_phase     = 0;
                                n_cmd_stop  = 1'b1;
                                n_addr      = addr + 1;
                                n_transfer  = transfer + 1;
                            end
                            default: begin
                                n_phase = phase + 1;
                                n_cmd_write = 1'b1;
                            end
                        endcase
                    end
                end
            end
            WAIT: begin
                wait_start = 1'b1;
                if (transfer == 42) begin
                    target = 1000;
                    n_cmd_stop = 1'b0;
                    if (wait_done) begin
                        n_transfer  = 0;
                        n_cmd_start = 1'b1;
                    end
                end else begin
                    target = 100;
                    n_cmd_stop = 1'b0;
                    if (wait_done) n_cmd_start = 1'b1;
                end
            end
            QVGA_RGB: begin
                if (transfer == 16) begin
                    n_cmd_start = 1'b0;
                    n_cmd_write = 1'b0;
                end else begin
                    n_cmd_start = 1'b0;
                    n_cmd_write = 1'b0;
                    if (done) begin // done cycle에만 출력됨. 1 cycle의 조합출력 -> registering
                        if (busy) begin // busy하면 phase는 진행되어야지
                            n_phase = phase + 1;
                            n_cmd_write = 1'b1;
                            case (phase)
                                2'd0: begin
                                    // start완료 시 done, data 전송 없음
                                    // flag로 동작
                                    // OV7670 주소 전송 명령
                                end
                                2'd1: begin
                                    // register 주소 전송 명령
                                end
                                2'd2: begin
                                    // data 전송 명령
                                    // 다음 rom 주소로 업데이트
                                    n_addr = addr + 1;
                                end
                                2'd3: begin
                                    // 전송 완료
                                    n_cmd_start = 1'b0;
                                    n_cmd_write = 1'b0;
                                    n_phase     = 0;
                                    n_cmd_stop  = 1'b1;
                                    n_addr      = addr + 1;
                                    n_transfer  = transfer + 1;
                                end
                                default: begin
                                    n_phase = phase + 1;
                                    n_cmd_write = 1'b1;
                                end
                            endcase
                        end else begin  //busy하지 않으면 start 해야지
                            n_cmd_start = 1'b1;
                            n_cmd_stop  = 1'b0;
                        end
                    end
                end
            end
            STOP: begin
                n_cmd_start = 1'b0;
                n_cmd_stop  = 1'b0;
                n_cmd_read  = 1'b0;
                n_cmd_write = 1'b0;
            end
            default: begin
                n_cmd_start = cmd_start;
                n_cmd_write = cmd_write;
                n_cmd_read  = cmd_read;
                n_cmd_stop  = cmd_stop;
                n_ack_in    = ack_in;
                n_addr      = addr;
                n_transfer  = transfer;
                wait_start  = 0;
            end
        endcase
    end
endmodule
