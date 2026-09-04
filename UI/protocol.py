PC_MAIN = 0
PC_MENU = 1
PC_READY = 2
PC_GAME_ING = 3
PC_STOP = 4


# =========================================================
# SONG NUMBER
#
# UI currentIndex / FPGA song_decoder mapping:
#
# 0 = 학교종
# 1 = 나비야
# 2 = Mozart - Eine Kleine
# 3 = Ode to Joy
# 4 = Vivaldi - Spring
#
# SONG_NONE은 MAIN/MENU 로그 표현용 alias.
# FPGA song_decoder는 PC_READY일 때만 song을 latch하므로
# 값 0을 공유해도 현재 RTL 동작에는 영향이 없다.
# =========================================================

SONG_NONE = 0

SONG_SCHOOL_BELL = 0
SONG_NABIYA = 1
SONG_MOZART_EINE_KLEINE = 2
SONG_ODE_TO_JOY = 3
SONG_VIVALDI_SPRING = 4


PC_STATE_NAMES = {
    PC_MAIN: "MAIN",
    PC_MENU: "MENU",
    PC_READY: "READY",
    PC_GAME_ING: "GAME_ING",
    PC_STOP: "STOP",
}


SONG_NAMES = {
    SONG_SCHOOL_BELL: "SCHOOL_BELL",
    SONG_NABIYA: "NABIYA",
    SONG_MOZART_EINE_KLEINE: "MOZART_EINE_KLEINE",
    SONG_ODE_TO_JOY: "ODE_TO_JOY",
    SONG_VIVALDI_SPRING: "VIVALDI_SPRING",
}


# =========================================================
# pattern_stick RTL state
# =========================================================

PATTERN_IDLE = 0
PATTERN_START = 1
PATTERN_READY = 2
PATTERN_1 = 3
PATTERN_2 = 4
PATTERN_3 = 5
PATTERN_4 = 6
PATTERN_STOP = 7


PATTERN_NAMES = {
    PATTERN_IDLE: "IDLE",
    PATTERN_START: "START",
    PATTERN_READY: "READY (ZONE4)",
    PATTERN_1: "PATTERN_1 (ZONE1)",
    PATTERN_2: "PATTERN_2 (ZONE2)",
    PATTERN_3: "PATTERN_3 (ZONE3)",
    PATTERN_4: "PATTERN_4 (ZONE4)",
    PATTERN_STOP: "STOP",
}


# =========================================================
# FPGA -> PC
#
# [63:62] GAME_FSM
# [61:52] RED_X
# [51:42] RED_Y
# [41:32] GREEN_X
# [31:22] GREEN_Y
# [21:19] PATTERN
# [18:12] VOL
# [11:4]  SPEED
# [3:0]   SCORE
# =========================================================

def decode_fpga_data(
    value: int
) -> dict:

    value = int(value) & 0xFFFFFFFFFFFFFFFF

    return {
        "game_fsm":
            (value >> 62)
            & 0x03,

        "red_x":
            (value >> 52)
            & 0x3FF,

        "red_y":
            (value >> 42)
            & 0x3FF,

        "green_x":
            (value >> 32)
            & 0x3FF,

        "green_y":
            (value >> 22)
            & 0x3FF,

        "pattern":
            (value >> 19)
            & 0x07,

        "volume":
            (value >> 12)
            & 0x7F,

        "speed":
            (value >> 4)
            & 0xFF,

        "score":
            value
            & 0x0F,
    }


# =========================================================
# PC -> FPGA
#
# [7:4] GAME_STATE
# [3:0] SONG_NUM
# =========================================================

def encode_pc_data(
    game_state: int,
    song_num: int
) -> int:

    return (
        (
            int(game_state)
            & 0x0F
        )
        << 4
    ) | (
        int(song_num)
        & 0x0F
    )
