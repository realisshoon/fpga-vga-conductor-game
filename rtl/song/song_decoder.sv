module song_decoder (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] i_pc_state,
    input  logic [2:0] i_pc_song,

    output logic [2:0] o_song_num,
    output logic [7:0] o_song_bpm
);

    // PC State
    localparam MAIN        = 3'b000;
    localparam MENU        = 3'b001;
    localparam PC_READY    = 3'b010;
    localparam PC_GAME_ING = 3'b011;
    localparam PC_STOP     = 3'b100;

    // Song Number
    localparam SONG_0      = 3'b000;  // 학교종
    localparam SONG_1      = 3'b001;  // 나비야
    localparam SONG_2      = 3'b010;  // Mozart - Eine Kleine
    localparam SONG_3      = 3'b011;  // Ode to Joy
    localparam SONG_4      = 3'b100;  // Vivaldi - Spring

    // Actual MIDI BPM
    localparam BPM_SONG_0  = 8'd120;
    localparam BPM_SONG_1  = 8'd110;
    localparam BPM_SONG_2  = 8'd145;
    localparam BPM_SONG_3  = 8'd100;
    localparam BPM_SONG_4  = 8'd115;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_song_num <= 3'b000;
            o_song_bpm <= 8'd0;
        end else if (i_pc_state == PC_READY) begin
            o_song_num <= i_pc_song;

            case (i_pc_song)
                SONG_0: o_song_bpm <= BPM_SONG_0;
                SONG_1: o_song_bpm <= BPM_SONG_1;
                SONG_2: o_song_bpm <= BPM_SONG_2;
                SONG_3: o_song_bpm <= BPM_SONG_3;
                SONG_4: o_song_bpm <= BPM_SONG_4;
                
                default: o_song_bpm <= 8'd0;
            endcase
        end
    end

endmodule
