import sys
from pathlib import Path

from PySide6.QtCore import QObject, QTimer
from PySide6.QtWidgets import QApplication

from UI.ui import MainWindow
from audio_manager import AudioManager
from midi_player import MidiPlayer
from serial_comm import SerialComm
from capture_manager import CaptureManager

from protocol import (
    encode_pc_data,
    decode_fpga_data,
    PC_MAIN,
    PC_MENU,
    PC_READY,
    PC_GAME_ING,
    PC_STOP,
    SONG_NONE,
    SONG_SCHOOL_BELL,
    SONG_NABIYA,
    SONG_MOZART_EINE_KLEINE,
    SONG_ODE_TO_JOY,
    SONG_VIVALDI_SPRING,
    PC_STATE_NAMES,
    SONG_NAMES,
    PATTERN_IDLE,
    PATTERN_START,
    PATTERN_READY,
    PATTERN_1,
    PATTERN_2,
    PATTERN_3,
    PATTERN_4,
    PATTERN_STOP,
    PATTERN_NAMES,
)


# =========================================================
# UART CONFIG
# =========================================================

# UART_MODE = "MOCK"
UART_MODE = "REAL"
UART_PORT = "COM9"
UART_BAUDRATE = 115200
UART_POLL_MS = 5


# =========================================================
# CAPTURE CONFIG
# =========================================================

CAPTURE_DEVICE_INDEX = None
CAPTURE_WIDTH = 640
CAPTURE_HEIGHT = 480
CAPTURE_FPS = 30
CAPTURE_SCAN_MAX_INDEX = 8
CAPTURE_ALLOW_INDEX_FALLBACK = False

CAPTURE_NAME_HINTS = (
    "capture",
    "hdmi",
    "usb video",
    "uvc",
    "video capture",
)

CAPTURE_REJECT_HINTS = (
    "integrated camera",
    "webcam",
    "obs virtual",
    "virtual camera",
)


# =========================================================
# 4/4 PATTERN
#
# FPGA pattern_stick:
# P1(Z1) -> P2(Z2) -> P3(Z3) -> P4(Z4) -> P1(Z1)
#
# 정상 PATTERN 전환 1회 = MIDI quarter-note 1박 진행
# =========================================================

PATTERN_SEQUENCE = (
    PATTERN_1,
    PATTERN_2,
    PATTERN_3,
    PATTERN_4,
)

NEXT_MUSIC_PATTERN = {
    PATTERN_1: PATTERN_2,
    PATTERN_2: PATTERN_3,
    PATTERN_3: PATTERN_4,
    PATTERN_4: PATTERN_1,
}


class GameController(QObject):

    def __init__(self, window):
        super().__init__()

        print()
        print("=" * 70)
        print("[BOOT] MAESTRO PC CONTROLLER START")
        print("=" * 70)

        self.window = window
        self.audio = AudioManager()
        self.midi = MidiPlayer()

        self.serial = SerialComm(
            port=UART_PORT,
            baudrate=UART_BAUDRATE,
        )

        self.uart_enabled = False

        self.uart_timer = QTimer(self)
        self.uart_timer.setInterval(UART_POLL_MS)
        self.uart_timer.timeout.connect(self.poll_uart)

        self.capture = CaptureManager(
            window=self.window,
            device_index=CAPTURE_DEVICE_INDEX,
            width=CAPTURE_WIDTH,
            height=CAPTURE_HEIGHT,
            fps=CAPTURE_FPS,
            scan_max_index=CAPTURE_SCAN_MAX_INDEX,
            allow_unnamed_fallback=CAPTURE_ALLOW_INDEX_FALLBACK,
            preferred_name_keywords=CAPTURE_NAME_HINTS,
            reject_name_keywords=CAPTURE_REJECT_HINTS,
            parent=self,
        )

        base = Path(__file__).resolve().parent

        self.song_paths = {
            SONG_SCHOOL_BELL:
                base / "assets" / "songs" / "school_bell_orchestra.mid",

            SONG_NABIYA:
                base / "assets" / "songs" / "nabiya_full_orchestra.mid",

            SONG_MOZART_EINE_KLEINE:
                base / "assets" / "songs" / "Mozart - Eine Kleine.mid",

            SONG_ODE_TO_JOY:
                base / "assets" / "songs" / "ode_to_joy.mid",

            SONG_VIVALDI_SPRING:
                base / "assets" / "songs" / "vivaldi-spring.mid",
        }

        self.scene = "TITLE"
        self.pc_state = PC_MAIN
        self.song_num = SONG_NONE

        self.ready_zone4_reached = False
        self.midi_started = False

        # 마지막으로 음악 1박을 허가한 PATTERN
        self.music_pattern = None
        self.music_beat_count = 0

        if str(UART_MODE).strip().upper() == "REAL":
            initial_red_x = 1023
            initial_red_y = 1023
            initial_green_x = 1023
            initial_green_y = 1023
        else:
            initial_red_x = 160
            initial_red_y = 120
            initial_green_x = 145
            initial_green_y = 55

        self.latest_data = {
            "game_fsm": 0,
            "red_x": initial_red_x,
            "red_y": initial_red_y,
            "green_x": initial_green_x,
            "green_y": initial_green_y,
            "pattern": PATTERN_IDLE,
            "volume": 50,
            "speed": 120,
            "score": 5,
        }

        print(
            "[MOCK GREEN XY] "
            f"({self.latest_data['green_x']}, "
            f"{self.latest_data['green_y']})"
        )

        (
            self.last_seated_target,
            self.last_standing_target,
        ) = self.audience_targets_from_score(
            self.latest_data["score"]
        )

        self.result_timer = QTimer(self)
        self.result_timer.setSingleShot(True)
        self.result_timer.timeout.connect(self.close_result)

        self.return_timer = QTimer(self)
        self.return_timer.setSingleShot(True)
        self.return_timer.timeout.connect(
            self.return_to_main_after_stop
        )

        self.midi.song_finished.connect(
            self.finish_song
        )

        self.connect_ui()
        self.setup_uart()

        self.window.update_fpga_data(
            self.latest_data
        )
        self.window.show_title_screen()

        self.audio.start_title_bgm()

        print()
        print("[GAME] SCENE = TITLE")

        self.send_state(
            event="APP_BOOT",
            scene_from="OFF",
            scene_to="TITLE",
        )

        print()
        print("=" * 70)
        print("[BOOT] MAESTRO READY")
        print("=" * 70)

    # ==================================================
    # RESET
    # ==================================================

    def reset_music_gate(self):
        self.music_pattern = None
        self.music_beat_count = 0

    # ==================================================
    # UART
    # ==================================================

    def setup_uart(self):
        mode = str(UART_MODE).strip().upper()

        if mode != "REAL":
            self.uart_enabled = False
            self.window.connection_label.setText(
                "● MOCK MODE"
            )

            print()
            print("=" * 70)
            print("[UART] MODE = MOCK")
            print("[UART] REAL SERIAL COMMUNICATION = OFF")
            print("[UART] DEV BUTTON / SLIDER TEST = ON")
            print("=" * 70)
            return

        try:
            self.serial.connect()
            self.uart_enabled = True

            self.window.connection_label.setText(
                f"● UART {UART_PORT}"
            )

            self.uart_timer.start()

            print()
            print("=" * 70)
            print("[UART] CONNECT SUCCESS")
            print(f"PORT         : {UART_PORT}")
            print(f"BAUD         : {UART_BAUDRATE}")
            print("FORMAT       : 8N1")
            print("PC -> FPGA   : 1 Byte")
            print("FPGA -> PC   : 8 Byte / 64 bit")
            print("RX ENDIAN    : LITTLE")
            print("=" * 70)

        except Exception as e:
            self.uart_enabled = False
            self.window.connection_label.setText(
                "● MOCK MODE"
            )

            print()
            print("=" * 70)
            print("[UART] CONNECT FAIL")
            print(f"PORT         : {UART_PORT}")
            print(f"ERROR        : {e}")
            print("FALLBACK     : MOCK MODE")
            print("=" * 70)

    def poll_uart(self):
        if not self.uart_enabled:
            return

        for _ in range(16):
            value = self.serial.receive_fpga_data()

            if value is None:
                break

            data = decode_fpga_data(value)

            previous_game_fsm = int(
                self.latest_data["game_fsm"]
            )
            previous_pattern = int(
                self.latest_data["pattern"]
            )

            if (
                int(data["game_fsm"]) != previous_game_fsm
                or
                int(data["pattern"]) != previous_pattern
            ):
                print()
                print("=" * 70)
                print("[FPGA TX -> PC RX]")
                print(f"RAW 64BIT    : 0x{value:016X}")
                print(
                    f"GAME_FSM     : "
                    f"{data['game_fsm']}"
                )
                print(
                    f"PATTERN      : "
                    f"{data['pattern']} "
                    f"({PATTERN_NAMES.get(data['pattern'], 'UNKNOWN')})"
                )
                print(
                    f"RED XY       : "
                    f"({data['red_x']}, {data['red_y']})"
                )
                print(
                    f"GREEN XY     : "
                    f"({data['green_x']}, {data['green_y']})"
                )
                print(f"VOLUME       : {data['volume']}")
                print(f"SPEED        : {data['speed']}")
                print(f"SCORE        : {data['score'] * 10}")
                print("=" * 70)

            self.handle_fpga_data(data)

    # ==================================================
    # AUDIENCE
    # ==================================================

    def audience_targets_from_score(self, score):
        score = max(0, min(10, int(score)))

        seated_table = {
            0: 6,
            1: 14,
            2: 24,
            3: 34,
            4: 44,
            5: 52,
            6: 52,
            7: 52,
            8: 52,
            9: 52,
            10: 52,
        }

        standing_table = {
            0: 0,
            1: 0,
            2: 0,
            3: 0,
            4: 0,
            5: 0,
            6: 4,
            7: 8,
            8: 12,
            9: 16,
            10: 20,
        }

        return (
            seated_table[score],
            standing_table[score],
        )

    # ==================================================
    # UI SIGNAL
    # ==================================================

    def connect_ui(self):
        self.window.title_start_requested.connect(
            self.enter_main_from_title
        )
        self.window.menu_requested.connect(
            self.go_menu
        )
        self.window.back_requested.connect(
            self.back_to_main
        )
        self.window.start_requested.connect(
            self.start_ready
        )
        self.window.stop_requested.connect(
            self.abort_game
        )

        self.window.mock_zone4_ready_requested.connect(
            self.mock_zone4_ready
        )
        self.window.mock_zone1_start_requested.connect(
            self.mock_zone1_start
        )
        self.window.mock_bpm_requested.connect(
            self.mock_bpm
        )
        self.window.mock_volume_requested.connect(
            self.mock_volume
        )
        self.window.mock_score_requested.connect(
            self.mock_score
        )
        self.window.mock_song_end_requested.connect(
            self.finish_song
        )

    # ==================================================
    # PC -> FPGA
    # ==================================================

    def send_state(
        self,
        event,
        scene_from=None,
        scene_to=None,
    ):
        value = encode_pc_data(
            self.pc_state,
            self.song_num,
        )

        state_name = PC_STATE_NAMES.get(
            self.pc_state,
            "UNKNOWN",
        )

        if (
            self.pc_state in (PC_MAIN, PC_MENU)
            and
            self.song_num == SONG_NONE
        ):
            song_name = "NONE"
        else:
            song_name = SONG_NAMES.get(
                self.song_num,
                "UNKNOWN",
            )

        binary = f"{value:08b}"

        if scene_from is None:
            scene_from = self.scene

        if scene_to is None:
            scene_to = self.scene

        print()
        print("=" * 70)
        print("[PC TX -> FPGA RX]")
        print(f"EVENT        : {event}")
        print(f"SCENE        : {scene_from} -> {scene_to}")
        print(
            f"STATE        : "
            f"{state_name} ({self.pc_state})"
        )
        print(
            f"SONG         : "
            f"{song_name} ({self.song_num})"
        )
        print(f"DATA HEX     : 0x{value:02X}")
        print(f"DATA DEC     : {value}")
        print(
            f"DATA BIN     : "
            f"{binary[:4]}_{binary[4:]}"
        )
        print(f"STATE[7:4]   : {binary[:4]}")
        print(f"SONG [3:0]   : {binary[4:]}")
        print(
            "PACKET       : "
            "[GAME_STATE 4bit][SONG_NUM 4bit]"
        )
        print("=" * 70)

        if self.uart_enabled:
            success = self.serial.send_pc_data(value)
            print(
                "[UART SEND] "
                + ("SUCCESS" if success else "FAIL")
            )
        else:
            print("[UART SEND] SKIP (MOCK MODE)")

    # ==================================================
    # TITLE / MAIN / MENU
    # ==================================================

    def _reset_mock_xy(self):
        if self.uart_enabled:
            self.latest_data["red_x"] = 1023
            self.latest_data["red_y"] = 1023
            self.latest_data["green_x"] = 1023
            self.latest_data["green_y"] = 1023
        else:
            self.latest_data["red_x"] = 160
            self.latest_data["red_y"] = 120
            self.latest_data["green_x"] = 145
            self.latest_data["green_y"] = 55

    def enter_main_from_title(self):
        old_scene = self.scene

        self.audio.stop_title_bgm(700)
        self.midi.stop()

        self.scene = "MAIN"
        self.pc_state = PC_MAIN
        self.song_num = SONG_NONE

        self.latest_data["game_fsm"] = 0
        self.latest_data["pattern"] = PATTERN_IDLE
        self.latest_data["score"] = 5
        self._reset_mock_xy()

        self.ready_zone4_reached = False
        self.midi_started = False
        self.reset_music_gate()

        self.window.show_game_screen()
        self.window.set_scene("MAIN")
        self.window.update_fpga_data(
            self.latest_data
        )

        self.send_state(
            event="TITLE_START_BUTTON",
            scene_from=old_scene,
            scene_to="MAIN",
        )

    def back_to_main(self):
        old_scene = self.scene

        self.audio.stop_all()
        self.midi.stop()

        self.scene = "MAIN"
        self.pc_state = PC_MAIN
        self.song_num = SONG_NONE

        self.ready_zone4_reached = False
        self.midi_started = False
        self.reset_music_gate()

        self.latest_data["game_fsm"] = 0
        self.latest_data["pattern"] = PATTERN_IDLE
        self.latest_data["score"] = 5
        self._reset_mock_xy()

        self.window.set_scene("MAIN")
        self.window.update_fpga_data(
            self.latest_data
        )

        self.send_state(
            event="BACK_TO_MAIN",
            scene_from=old_scene,
            scene_to="MAIN",
        )

    def go_menu(self):
        old_scene = self.scene

        self.audio.stop_all()
        self.midi.stop()

        self.scene = "MENU"
        self.pc_state = PC_MENU
        self.song_num = SONG_NONE

        self.ready_zone4_reached = False
        self.midi_started = False
        self.reset_music_gate()

        self.latest_data["game_fsm"] = 0
        self.latest_data["pattern"] = PATTERN_IDLE

        self.window.set_scene("MENU")
        self.window.update_fpga_data(
            self.latest_data
        )

        self.send_state(
            event="MENU_BUTTON_CLICK",
            scene_from=old_scene,
            scene_to="MENU",
        )

    # ==================================================
    # MENU -> READY
    # ==================================================

    def start_ready(self, combo_index):
        self.song_num = int(combo_index)

        if self.song_num not in self.song_paths:
            print(
                "[ERROR] INVALID SONG NUM :",
                self.song_num,
            )
            return

        old_scene = self.scene

        self.audio.stop_all()
        self.midi.stop()

        self.ready_zone4_reached = False
        self.midi_started = False
        self.reset_music_gate()

        self.scene = "READY"
        self.pc_state = PC_READY

        self.latest_data["game_fsm"] = 1
        self.latest_data["pattern"] = PATTERN_START
        self.latest_data["score"] = 5

        if not self.uart_enabled:
            self.latest_data["red_x"] = 160
            self.latest_data["red_y"] = 120
            self.latest_data["green_x"] = 145
            self.latest_data["green_y"] = 55

        (
            self.last_seated_target,
            self.last_standing_target,
        ) = self.audience_targets_from_score(5)

        self.window.set_scene("READY")
        self.window.update_fpga_data(
            self.latest_data
        )

        self.audio.start_applause()

        print()
        print("=" * 70)
        print("[GAME READY]")
        print(
            f"SONG         : "
            f"{SONG_NAMES[self.song_num]}"
        )
        print("GAME_FSM     : READY (1)")
        print("PATTERN      : START (1)")
        print("SCORE        : 50")
        print("SEATED       : 52 / 52 FULL")
        print("STANDING     : 0")
        print("APPLAUSE     : ON")
        print("MIDI         : WAIT")
        print("NEXT         : PATTERN READY(2) / ZONE4")
        print(
            "MOCK GREEN XY: "
            f"({self.latest_data['green_x']}, "
            f"{self.latest_data['green_y']})"
        )
        print("=" * 70)

        self.send_state(
            event="SONG_SELECT_CONFIRM",
            scene_from=old_scene,
            scene_to="READY",
        )

    # ==================================================
    # READY -> PLAYING
    #
    # P1(ZONE1) = 첫 1박
    # ==================================================

    def begin_game(self):
        if self.scene == "PLAYING":
            return

        if self.midi_started:
            return

        old_scene = self.scene

        self.scene = "PLAYING"
        self.pc_state = PC_GAME_ING

        self.audio.stop_applause()
        self.audio.stop_booing()

        (
            self.last_seated_target,
            self.last_standing_target,
        ) = self.audience_targets_from_score(
            self.latest_data["score"]
        )

        self.window.set_scene("PLAYING")

        self.send_state(
            event="ZONE1_GAME_START_SYNC",
            scene_from=old_scene,
            scene_to="PLAYING",
        )

        song_path = self.song_paths[self.song_num]

        if not song_path.exists():
            print(
                "[MIDI] FILE NOT FOUND :",
                song_path,
            )
            return

        bpm = int(self.latest_data["speed"])

        if bpm <= 0:
            bpm = 120

        volume = int(
            self.latest_data["volume"]
        )

        self.midi.set_volume(volume)

        if not self.midi.play(
            song_path,
            bpm,
        ):
            print("[MIDI] START FAIL")
            return

        self.midi_started = True

        self.music_pattern = PATTERN_1
        self.music_beat_count = 1

        # ZONE1에 들어온 순간 첫 1박 허가
        self.midi.advance_one_beat()

        print()
        print("=" * 70)
        print("[CONDUCT START]")
        print("ZONE         : 1 REACHED")
        print("PATTERN      : PATTERN_1 (3)")
        print("GAME_FSM     : GAME_ING (2)")
        print(f"SONG         : {song_path.name}")
        print(f"BPM          : {bpm}")
        print(f"VOLUME       : {volume}")
        print("APPLAUSE     : OFF")
        print("MIDI         : PLAY 1 BEAT")
        print("NEXT         : WAIT ZONE2 / PATTERN_2")
        print("=" * 70)

    # ==================================================
    # PATTERN -> MIDI ONE BEAT
    # ==================================================

    def handle_music_pattern(
        self,
        incoming_pattern,
    ):
        if (
            self.scene != "PLAYING"
            or
            not self.midi_started
        ):
            return

        incoming_pattern = int(
            incoming_pattern
        )

        if incoming_pattern not in PATTERN_SEQUENCE:
            return

        # 같은 상태 반복 패킷은 절대 다음 박으로 처리하지 않음.
        if incoming_pattern == self.music_pattern:
            return

        expected_pattern = NEXT_MUSIC_PATTERN.get(
            self.music_pattern
        )

        # FPGA가 순서를 보장하지만 PC에서도 방어.
        if incoming_pattern != expected_pattern:
            print()
            print("-" * 70)
            print("[MIDI] PATTERN CHANGE IGNORED")
            print(
                f"LAST         : "
                f"{PATTERN_NAMES.get(self.music_pattern, self.music_pattern)}"
            )
            print(
                f"INCOMING     : "
                f"{PATTERN_NAMES.get(incoming_pattern, incoming_pattern)}"
            )
            print(
                f"EXPECTED     : "
                f"{PATTERN_NAMES.get(expected_pattern, expected_pattern)}"
            )
            print("-" * 70)
            return

        self.music_pattern = incoming_pattern
        self.music_beat_count += 1

        self.midi.advance_one_beat()

        zone_number = (
            incoming_pattern
            - PATTERN_1
            + 1
        )

        next_pattern = NEXT_MUSIC_PATTERN[
            incoming_pattern
        ]

        next_zone = (
            next_pattern
            - PATTERN_1
            + 1
        )

        print()
        print("=" * 70)
        print("[MIDI] VALID CONDUCT BEAT")
        print(
            f"BEAT COUNT   : "
            f"{self.music_beat_count}"
        )
        print(
            f"PATTERN      : "
            f"{PATTERN_NAMES.get(incoming_pattern, incoming_pattern)}"
        )
        print(
            f"ZONE         : "
            f"{zone_number} REACHED"
        )
        print(
            "ACTION       : "
            "PLAY NEXT 1/4 OF 4/4 BAR = 1 BEAT"
        )
        print(
            f"NEXT         : "
            f"ZONE{next_zone}"
        )
        print("=" * 70)

    # ==================================================
    # FPGA -> PC / MOCK -> SAME PATH
    # ==================================================

    def handle_fpga_data(self, data):
        previous_score = int(
            self.latest_data["score"]
        )

        incoming_pattern = int(
            data["pattern"]
        )

        incoming_game_fsm = int(
            data["game_fsm"]
        )

        # READY: 최초 Zone4
        if self.scene == "READY":
            if (
                incoming_pattern == PATTERN_READY
                and
                not self.ready_zone4_reached
            ):
                self.ready_zone4_reached = True
                self.audio.stop_applause()

                print()
                print("=" * 70)
                print("[CONDUCT READY]")
                print("PATTERN      : READY (2)")
                print("MEANING      : ZONE4 REACHED")
                print(
                    f"RED STICK    : "
                    f"({data['red_x']}, {data['red_y']})"
                )
                print(
                    f"GREEN POINT  : "
                    f"({data['green_x']}, {data['green_y']})"
                )
                print("ACTION       : APPLAUSE STOP")
                print("MIDI         : WAIT")
                print("NEXT         : MOVE ZONE4 -> ZONE1")
                print("=" * 70)

        # PLAYING
        if self.scene == "PLAYING":
            (
                new_seated,
                new_standing,
            ) = self.audience_targets_from_score(
                data["score"]
            )

            old_total = (
                self.last_seated_target
                + self.last_standing_target
            )
            new_total = (
                new_seated
                + new_standing
            )

            if new_total < old_total:
                leaving = old_total - new_total

                print()
                print("-" * 70)
                print("[AUDIENCE EXIT ACTION]")
                print(
                    f"SCORE        : "
                    f"{previous_score * 10}"
                    f" -> "
                    f"{int(data['score']) * 10}"
                )
                print(f"LEAVING      : {leaving}")
                print("-" * 70)

                try:
                    self.audio.start_booing()
                except AttributeError:
                    pass

            elif new_total > old_total:
                entering = new_total - old_total

                print()
                print("-" * 70)
                print("[AUDIENCE ENTER ACTION]")
                print(
                    f"SCORE        : "
                    f"{previous_score * 10}"
                    f" -> "
                    f"{int(data['score']) * 10}"
                )
                print(f"ENTERING     : {entering}")
                print("-" * 70)

                self.audio.stop_booing()

            self.last_seated_target = (
                new_seated
            )
            self.last_standing_target = (
                new_standing
            )

            # SPEED/VOLUME 적용 후 이번 PATTERN의 1박 허가
            if self.midi_started:
                speed = int(
                    data["speed"]
                )
                volume = int(
                    data["volume"]
                )

                if speed > 0:
                    self.midi.set_bpm(speed)

                self.midi.set_volume(volume)

                self.handle_music_pattern(
                    incoming_pattern
                )

        # SAVE / UI
        self.latest_data = dict(data)

        self.window.update_fpga_data(
            self.latest_data
        )

        # READY -> PLAYING
        if (
            self.scene == "READY"
            and
            incoming_pattern == PATTERN_1
            and
            incoming_game_fsm == 2
        ):
            print()
            print("=" * 70)
            print("[FPGA TX -> PC RX]")
            print("EVENT        : ZONE1 START")
            print("PATTERN      : PATTERN_1 (3)")
            print("GAME_FSM     : GAME_ING (2)")
            print(
                f"RED STICK    : "
                f"({data['red_x']}, {data['red_y']})"
            )
            print(
                f"GREEN POINT  : "
                f"({data['green_x']}, {data['green_y']})"
            )
            print(
                f"ZONE4 READY  : "
                f"{'YES' if self.ready_zone4_reached else 'NO'}"
            )
            print("ACTION       : LOAD MIDI + FIRST 1 BEAT")
            print("=" * 70)

            self.begin_game()

    # ==================================================
    # SONG END / STOP
    # ==================================================

    def finish_song(self):
        if self.scene not in (
            "READY",
            "PLAYING",
        ):
            return

        old_scene = self.scene

        self.midi.stop()
        self.audio.stop_applause()
        self.audio.stop_booing()

        self.midi_started = False
        self.reset_music_gate()

        final_score = int(
            self.latest_data["score"]
        )

        self.scene = "RESULT"
        self.window.set_result(
            final_score
        )

        self.audio.play_result(
            final_score
        )

        print()
        print("=" * 70)
        print("[GAME] SONG FINISHED")
        print(
            f"SCENE        : "
            f"{old_scene} -> RESULT"
        )
        print(
            f"FINAL SCORE  : "
            f"{final_score * 10} / 100"
        )
        print("NEXT         : 3 sec -> PC_STOP")
        print("=" * 70)

        self.result_timer.start(3000)

    def close_result(self):
        old_scene = self.scene

        self.scene = "STOP"
        self.pc_state = PC_STOP

        self.send_state(
            event="RESULT_TIMEOUT_STOP",
            scene_from=old_scene,
            scene_to="STOP",
        )

        self.window.stage.close_curtain()
        self.return_timer.start(1700)

    def return_to_main_after_stop(self):
        old_scene = self.scene

        self.scene = "MAIN"
        self.pc_state = PC_MAIN
        self.song_num = SONG_NONE

        self.ready_zone4_reached = False
        self.midi_started = False
        self.reset_music_gate()

        self.latest_data["game_fsm"] = 0
        self.latest_data["pattern"] = PATTERN_IDLE
        self.latest_data["score"] = 5
        self._reset_mock_xy()

        self.audio.stop_all()
        self.midi.stop()

        self.window.set_scene("MAIN")
        self.window.update_fpga_data(
            self.latest_data
        )

        self.send_state(
            event="STOP_COMPLETE_RETURN_MAIN",
            scene_from=old_scene,
            scene_to="MAIN",
        )

    def abort_game(self):
        old_scene = self.scene

        self.midi.stop()
        self.audio.stop_all()

        self.midi_started = False
        self.reset_music_gate()

        self.scene = "STOP"
        self.pc_state = PC_STOP

        self.send_state(
            event="STOP_BUTTON_CLICK",
            scene_from=old_scene,
            scene_to="STOP",
        )

        self.window.stage.close_curtain()
        self.return_timer.start(1200)

    # ==================================================
    # DEV TEST
    # ==================================================

    def mock_zone4_ready(self):
        if self.scene != "READY":
            print()
            print(
                "[DEV TEST] "
                "ZONE 4 READY ignored - "
                "current scene is not READY"
            )
            return

        data = dict(self.latest_data)

        data["game_fsm"] = 1
        data["pattern"] = PATTERN_READY

        data["red_x"] = 160
        data["red_y"] = 30

        data["green_x"] = 145
        data["green_y"] = 45

        print()
        print("=" * 70)
        print("[DEV TEST] ZONE 4 READY")
        print("MOCK PATTERN : READY (2)")
        print("MOCK GAMEFSM : READY (1)")
        print("MOCK RED XY  : (160, 30)")
        print("MOCK GREEN XY: (145, 45)")
        print("EXPECT       : APPLAUSE STOP")
        print("EXPECT       : MIDI WAIT")
        print("=" * 70)

        self.handle_fpga_data(data)

    def mock_zone1_start(self):
        if self.scene != "READY":
            print()
            print(
                "[DEV TEST] "
                "ZONE 1 START ignored - "
                "current scene is not READY"
            )
            return

        if not self.ready_zone4_reached:
            print()
            print("=" * 70)
            print("[DEV TEST] ZONE 1 START BLOCKED")
            print(
                "REASON       : "
                "ZONE4 READY has not happened yet"
            )
            print(
                "FIRST        : "
                "press [ZONE 4 READY]"
            )
            print("=" * 70)
            return

        data = dict(self.latest_data)

        data["pattern"] = PATTERN_1
        data["game_fsm"] = 2

        data["red_x"] = 160
        data["red_y"] = 205

        data["green_x"] = 145
        data["green_y"] = 190

        print()
        print("=" * 70)
        print("[DEV TEST] ZONE 1 START")
        print("MOCK PATTERN : PATTERN_1 (3)")
        print("MOCK GAMEFSM : GAME_ING (2)")
        print("MOCK RED XY  : (160, 205)")
        print("MOCK GREEN XY: (145, 190)")
        print("EXPECT       : MIDI FIRST 1 BEAT")
        print("=" * 70)

        self.handle_fpga_data(data)

    def mock_bpm(self, bpm):
        data = dict(self.latest_data)
        data["speed"] = int(bpm)
        self.handle_fpga_data(data)

    def mock_volume(self, volume):
        data = dict(self.latest_data)
        data["volume"] = int(volume)
        self.handle_fpga_data(data)

    def mock_score(self, score):
        data = dict(self.latest_data)
        data["score"] = int(score)
        self.handle_fpga_data(data)

    # ==================================================
    # CLOSE
    # ==================================================

    def shutdown(self):
        print()
        print("=" * 70)
        print("[BOOT] SHUTDOWN")
        print("=" * 70)

        if self.uart_timer.isActive():
            self.uart_timer.stop()

        if self.result_timer.isActive():
            self.result_timer.stop()

        if self.return_timer.isActive():
            self.return_timer.stop()

        self.capture.close()
        self.serial.disconnect()
        self.midi.close()
        self.audio.close()


def main():
    print()
    print("=" * 70)
    print("[BOOT] MAIN START")
    print("=" * 70)

    app = QApplication(sys.argv)

    window = MainWindow()
    controller = GameController(window)

    window.controller = controller

    app.aboutToQuit.connect(
        controller.shutdown
    )

    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
