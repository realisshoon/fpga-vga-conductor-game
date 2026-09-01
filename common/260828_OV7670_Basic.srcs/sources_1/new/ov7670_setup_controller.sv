// `timescale 1ns / 1ps
// 
// module ov7670_setup_controller (
//     input  logic clk,
//     input  logic rst,
//     // external i2c port
//     output logic scl,
//     inout  wire  sda
// );
//     logic cmd_start, cmd_write, cmd_read, cmd_stop;
//     logic [7:0] tx_data, rx_data;
//     logic ack_in, ack_out;
//     logic busy, done;
// 
//     ov7670_setup_fsm U_FSM (
//         .clk(clk),
//         .rst(rst),
//         // to i2c master
//         .cmd_start(cmd_start),
//         .cmd_write(cmd_write),
//         .cmd_read (cmd_read),
//         .cmd_stop (cmd_stop),
//         .tx_data  (tx_data),
//         .ack_in   (ack_in),
// 
//         // from i2c master
//         .rx_data(rx_data),
//         .ack_out(ack_out),
//         .busy   (busy),
//         .done   (done)
//     );
// 
//     i2c_master_top U_I2C (
//         .clk(clk),
//         .rst(rst),
// 
//         // from fsm
//         .cmd_start(cmd_start),
//         .cmd_write(cmd_write),
//         .cmd_read(cmd_read),
//         .cmd_stop(cmd_stop),
//         .tx_data(tx_data),
//         .ack_in(ack_in),
// 
//         // to fsm
//         .rx_data(rx_data),
//         .ack_out(ack_out),
//         .busy   (busy),
//         .done   (done),
// 
//         // to ov7670
//         .scl(scl),
//         .sda(sda)
//     );
// 
// endmodule
// 
// module ov7670_setup_fsm (
//     // global signal
//     input  logic       clk,
//     input  logic       rst,
//     // to i2c master 
//     output logic       cmd_start,
//     output logic       cmd_write,
//     output logic       cmd_read,
//     output logic       cmd_stop,
//     output logic [7:0] tx_data,
//     output logic       ack_in,
//     // from i2c master
//     input  logic       ack_out,
//     input  logic [7:0] rx_data,
//     input  logic       busy,
//     input  logic       done
// );
//     // OV7670 address
//     localparam OV7670_ADDR = 7'h21;
//     // setup ROM
//     logic [7:0] addr, n_addr;
//     logic [7:0] mem[0:117];  // ov7670 setup data ROM
//     initial begin
//         $readmemh("ov7670_setup_rom.mem", mem);
//     end
// 
//     typedef enum logic [2:0] {
//         IDLE  = 3'd0,
//         WRITE,
//         WAIT,
//         STOP
//     } state_e;
// 
//     state_e c_state, n_state;
//     // i2c command & data
//     logic n_cmd_start;
//     logic n_cmd_write;
//     logic n_cmd_read;
//     logic n_cmd_stop;
//     logic n_ack_in;
// 
//     // byte transfer # in i2c
//     logic [1:0] phase, n_phase;
//     assign tx_data = (phase == 1) ? {OV7670_ADDR, 1'b0} : mem[addr];
// 
//     // transfer # of OV7670 setup data;
//     logic [5:0] transfer, n_transfer;
// 
//     // wait duration generator
//     logic wait_start, delay;
//     logic tick, wait_done;
//     logic [ 9:0] psc;
//     logic [12:0] cnt;
//     logic [12:0] target_r, target;
//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             tick      <= 1'b0;
//             wait_done <= 1'b0;
//             psc       <= 0;
//             cnt       <= 0;
//             target_r  <= 0;
//             delay     <= 0;
//         end else begin
//             if (wait_start) begin
//                 target_r <= target;
//                 if (psc == 1_000 - 1) begin
//                     tick <= 1'b1;
//                     psc  <= 0;
//                 end else begin
//                     tick <= 1'b0;
//                     psc  <= psc + 1;
//                 end
//                 if (tick) begin
//                     if (cnt == target_r - 1) begin
//                         wait_done <= 1'b1;
//                         delay <= 1'b0;
//                         cnt <= 0;
//                     end else begin
//                         cnt <= cnt + 1;
//                     end
//                 end
//             end else begin
//                 tick      <= 1'b0;
//                 wait_done <= 1'b0;
//                 psc       <= 0;
//                 cnt       <= 0;
//                 target_r  <= 0;
//             end
//         end
//     end
// 
//     // current state register
//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state   <= IDLE;
//             cmd_start <= 0;
//             cmd_write <= 0;
//             cmd_read  <= 0;
//             cmd_stop  <= 0;
//             ack_in    <= 0;
//             addr      <= 0;
//             transfer  <= 0;
//             phase     <= 0;
//         end else begin
//             cmd_start <= n_cmd_start;
//             cmd_write <= n_cmd_write;
//             cmd_read  <= n_cmd_read;
//             cmd_stop  <= n_cmd_stop;
//             ack_in    <= n_ack_in;
//             c_state   <= n_state;
//             addr      <= n_addr;
//             transfer  <= n_transfer;
//             phase     <= n_phase;
//         end
//     end
// 
//     // next state CL
//     always @(*) begin
//         n_state = c_state;
//         case (c_state)
//             IDLE: n_state = WRITE;
//             WRITE: if (transfer) n_state = WAIT;
//             WAIT: if (wait_done) n_state = WRITE;
//             STOP: n_state = STOP;
//             default: n_state = c_state;
//         endcase
//     end
// 
//     // output CL
//     always @(*) begin
//         n_cmd_start = cmd_start;
//         n_cmd_write = cmd_write;
//         n_cmd_read  = cmd_read;
//         n_cmd_stop  = cmd_stop;
//         n_ack_in    = ack_in;
//         n_addr      = addr;
//         n_transfer  = transfer;
//         n_phase     = phase;
//         target      = target_r;
//         wait_start  = 0;
//         case (c_state)
//             IDLE: begin
//                 n_cmd_start = 1'b1;
//             end
//             WRITE: begin
//                 n_cmd_start = 1'b0;
//                 n_cmd_write = 1'b0;
//                 n_cmd_stop  = 1'b0;
//                 n_cmd_read  = 1'b0;
//                 if (done) begin // done cycle에만 출력됨. 1 cycle의 조합출력 -> registering
//                     // done의 경우의 수
//                     // 1. Stop 이후 -> busy하지 않다.
//                     // 2. 나머지는 busy하다.
//                     if (busy) begin
//                         n_phase = phase + 1;
//                         n_cmd_write = 1'b1;
//                         case (phase)
//                             2'd0: begin
//                                 // start이후 done, wait command 상태이다.
//                                 // n_cmd_write를 넣어주자.
//                                 // n 을 변화시키므로 다음 cycle에 phase가 변하며 해당하는 data가 출력되게 함.
//                                 // 즉, 이 블럭에서의 기술은 phase[n-1]에서 phase[n]에 해당하는 데이터 전송을 명령한다.
//                                 n_cmd_write = 1'b1;
//                                 n_phase = phase + 1;
//                             end
//                             2'd1: begin
//                                 // phase[2]에서는 register의 주소값을 보낸다.
//                                 // 이미 주소는 장전되어있다.
//                                 // 따라서 변화시킬 필요없다.
//                                 n_phase = phase + 1;
//                                 n_cmd_write = 1'b1;
//                             end
//                             2'd2: begin
//                                 n_phase = phase + 1;
//                                 n_cmd_write = 1'b1;
//                                 // phase[3]에서 보낼 rom 주소로 업데이트
//                                 n_addr = addr + 1;
//                             end
//                             2'd3: begin
//                                 // phase[3]가 종료되고 done이 뜬 상태이다.
//                                 // 그렇다면 초기화를 해야한다.
//                                 n_phase     = 0;
//                                 n_cmd_start = 1'b0;
//                                 n_cmd_write = 1'b0;
//                                 // 멈추고 다음 write에 사용될 rom 주소를 미리 장전한다.
//                                 n_cmd_stop  = 1'b1;
//                                 n_addr      = addr + 1;
//                                 // 멈춤과 동시에 write phase가 진행되었다는 count를 증가한다.
//                                 n_transfer  = transfer + 1;
//                             end
//                             default: begin
//                                 n_phase = phase + 1;
//                                 n_cmd_write = 1'b1;
//                             end
//                         endcase
//                     end else begin
//                         // busy하지 않은 done이므로 stop이후 done이다.
//                         // transfer가 올라가면 wait state로 넘어간다.
//                         // 혹은 그대로 진행된다.
//                         // 이 블럭은 그대로 진행되는 후반부 Write를 담당한다.
// 
//                         // stop done 이후에는 즉시 start -> write가 필요해진다.
//                         // n_cmd_stop = cmd_stop이 default이므로
//                         // 따라서 다시 WRITE로 돌아왔을 때, stop을 먹인다면
//                         n_cmd_start = 1'b1;
//                         n_cmd_stop = 1'b0;
//                     end
//                 end
//             end
//             WAIT: begin
//                 wait_start = 1'b1;
//                 target = 3000;
//                 n_cmd_stop = 1'b0;
//                 if (wait_done) begin
//                     n_transfer  = 0;
//                     n_cmd_start = 1'b1;
//                 end
//             end
// 
// 
//             STOP: begin
//                 n_cmd_start = 1'b0;
//                 n_cmd_stop  = 1'b0;
//                 n_cmd_read  = 1'b0;
//                 n_cmd_write = 1'b0;
//             end
//             default: begin
//                 n_cmd_start = cmd_start;
//                 n_cmd_write = cmd_write;
//                 n_cmd_read  = cmd_read;
//                 n_cmd_stop  = cmd_stop;
//                 n_ack_in    = ack_in;
//                 n_addr      = addr;
//                 n_transfer  = transfer;
//                 wait_start  = 0;
//             end
//         endcase
//     end
// endmodule
// 
// 