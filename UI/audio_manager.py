from pathlib import Path

import pygame
from PySide6.QtCore import QObject


class AudioManager(QObject):

    def __init__(self):
        super().__init__()

        self.audio_dir = (
            Path(__file__).parent
            / "assets"
            / "audio"
        )

        # ==================================================
        # MIXER
        # ==================================================

        if not pygame.mixer.get_init():
            pygame.mixer.init(
                frequency=44100,
                size=-16,
                channels=2,
                buffer=512
            )

        pygame.mixer.set_num_channels(4)

        # ==================================================
        # SOUND LOAD
        # ==================================================

        self.title_bgm_sound = self._load_sound(
            "main_bgm.mp3"
        )

        self.applause_sound = self._load_sound(
            "game_start.wav"
        )

        self.result_0_30 = self._load_sound(
            "0~30.mp3"
        )

        self.result_30_60 = self._load_sound(
            "30~60.wav"
        )

        self.result_60_80 = self._load_sound(
            "60~80.wav"
        )

        self.result_80_100 = self._load_sound(
            "80~100.wav"
        )

        self.booing_sound = self._load_sound(
            "man_booing.mp3"
        )

        # ==================================================
        # CHANNEL
        # ==================================================

        self.applause_channel = pygame.mixer.Channel(0)
        self.result_channel = pygame.mixer.Channel(1)
        self.booing_channel = pygame.mixer.Channel(2)
        self.title_bgm_channel = pygame.mixer.Channel(3)

        # ==================================================
        # VOLUME
        # ==================================================

        self.applause_channel.set_volume(1.0)

        self.result_channel.set_volume(1.0)

        self.booing_channel.set_volume(0.85)

        self.title_bgm_channel.set_volume(0.55)

    # ==================================================
    # LOAD
    # ==================================================

    def _load_sound(
        self,
        filename
    ):

        path = (
            self.audio_dir
            / filename
        )

        try:
            sound = pygame.mixer.Sound(
                str(path)
            )

            print(
                f"[AUDIO] LOAD OK : {filename}"
            )

            return sound

        except Exception as e:
            print(
                f"[AUDIO] LOAD FAIL : {filename}"
            )

            print(
                f"[AUDIO] ERROR     : {e}"
            )

            return None

    # ==================================================
    # TITLE BGM
    # ==================================================

    def start_title_bgm(
        self
    ):

        if self.title_bgm_sound is None:
            return

        if self.title_bgm_channel.get_busy():
            return

        self.title_bgm_channel.set_volume(
            0.55
        )

        self.title_bgm_channel.play(
            self.title_bgm_sound,
            loops=-1
        )

        print(
            "[AUDIO] TITLE BGM START"
        )

    def stop_title_bgm(
        self,
        fade_ms=0
    ):

        if not self.title_bgm_channel.get_busy():
            return

        fade_ms = max(
            0,
            int(fade_ms)
        )

        if fade_ms > 0:
            self.title_bgm_channel.fadeout(
                fade_ms
            )

            print(
                f"[AUDIO] TITLE BGM FADE OUT : "
                f"{fade_ms} ms"
            )

        else:
            self.title_bgm_channel.stop()

            print(
                "[AUDIO] TITLE BGM STOP"
            )

    # ==================================================
    # APPLAUSE
    # ==================================================

    def start_applause(
        self
    ):

        if self.applause_sound is None:
            return

        self.applause_channel.stop()

        self.applause_channel.set_volume(
            1.0
        )

        self.applause_channel.play(
            self.applause_sound,
            loops=-1
        )

        print(
            "[AUDIO] APPLAUSE START"
        )

    def stop_applause(
        self
    ):

        self.applause_channel.stop()

    # ==================================================
    # BOOING
    #
    # 관객 퇴장 이벤트용
    # 기존 기능 그대로 유지
    # ==================================================

    def play_booing(
        self
    ):

        if self.booing_sound is None:
            return

        if self.booing_channel.get_busy():
            self.booing_channel.stop()

        self.booing_channel.set_volume(
            0.85
        )

        self.booing_channel.play(
            self.booing_sound
        )

        print(
            "[AUDIO] BOOING PLAY"
        )

    def stop_booing(
        self
    ):

        self.booing_channel.stop()

    # ==================================================
    # RESULT
    #
    # 0점       -> 0~30.mp3
    # 10~50점   -> 30~60.wav
    # 60~80점   -> 60~80.wav
    # 90~100점  -> 80~100.wav
    # ==================================================

    def play_result(
        self,
        score
    ):

        fpga_score = max(
            0,
            min(
                10,
                int(score)
            )
        )

        final_score = (
            fpga_score
            * 10
        )

        # 다른 사운드 정리
        self.stop_title_bgm()
        self.stop_applause()
        self.stop_booing()

        self.result_channel.stop()

        # ==================================================
        # RESULT SOUND SELECT
        # ==================================================

        if final_score == 0:
            sound = self.result_0_30
            filename = "0~30.mp3"

        elif final_score <= 50:
            sound = self.result_30_60
            filename = "30~60.wav"

        elif final_score <= 80:
            sound = self.result_60_80
            filename = "60~80.wav"

        else:
            sound = self.result_80_100
            filename = "80~100.wav"

        # ==================================================
        # RESULT VOLUME
        #
        # 0점 야유만 80%
        # 나머지는 100%
        # ==================================================

        if final_score == 0:
            result_volume = 0.80

        else:
            result_volume = 1.00

        self.result_channel.set_volume(
            result_volume
        )

        print(
            "============================================================"
        )

        print(
            "[AUDIO] RESULT"
        )

        print(
            f"  FPGA SCORE : {fpga_score}"
        )

        print(
            f"  UI SCORE   : {final_score}"
        )

        print(
            f"  SOUND      : {filename}"
        )

        print(
            f"  VOLUME     : "
            f"{int(result_volume * 100)}%"
        )

        print(
            "============================================================"
        )

        if sound is not None:
            self.result_channel.play(
                sound
            )

    def stop_result(
        self
    ):

        self.result_channel.stop()

    # ==================================================
    # GAME AUDIO STOP
    # ==================================================

    def stop_game_audio(
        self
    ):

        self.stop_applause()
        self.stop_booing()
        self.stop_result()

    # ==================================================
    # ALL STOP
    # ==================================================

    def stop_all(
        self
    ):

        self.stop_title_bgm()
        self.stop_applause()
        self.stop_booing()
        self.stop_result()

    # ==================================================
    # CLOSE
    # ==================================================

    def close(
        self
    ):

        self.stop_all()

        try:
            pygame.mixer.quit()

        except Exception:
            pass