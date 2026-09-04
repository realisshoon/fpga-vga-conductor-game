import threading
from pathlib import Path

import mido
import pygame.midi

from PySide6.QtCore import QObject, Signal


class MidiPlayer(QObject):
    song_finished = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)

        pygame.midi.init()

        self._output = None
        self._output_id = self._find_output_device()
        self._output_lock = threading.Lock()

        if self._output_id is not None:
            self._output = pygame.midi.Output(self._output_id)
            info = pygame.midi.get_device_info(self._output_id)
            name = self._decode_device_name(info[1]) if info else "UNKNOWN"
            print(f"[MIDI] OUTPUT ID = {self._output_id}")
            print(f"[MIDI] OUTPUT = {name}")
        else:
            print("[MIDI] OUTPUT DEVICE NOT FOUND")

        self._condition = threading.Condition()
        self._stop_event = threading.Event()
        self._thread = None

        self._events = []
        self._event_index = 0
        self._ticks_per_beat = 480
        self._total_ticks = 0
        self._current_tick = 0
        self._beat_credits = 0

        self._bpm = 120
        self._volume = 50

        self._active_notes = {}
        self._notes_silenced_for_pause = False
        self._song_path = None

        self.set_volume(self._volume)

    @staticmethod
    def _decode_device_name(value):
        if isinstance(value, bytes):
            return value.decode(errors="replace")
        return str(value)

    def _find_output_device(self):
        default_id = pygame.midi.get_default_output_id()

        if default_id is not None and default_id >= 0:
            info = pygame.midi.get_device_info(default_id)
            if info and int(info[3]) == 1:
                return int(default_id)

        for device_id in range(pygame.midi.get_count()):
            info = pygame.midi.get_device_info(device_id)
            if info and int(info[3]) == 1:
                return device_id

        return None

    def play(self, midi_path, bpm=120):
        path = Path(midi_path)

        if not path.exists():
            print(f"[MIDI] FILE NOT FOUND : {path}")
            return False

        self.stop()

        try:
            midi = mido.MidiFile(str(path))
        except Exception as exc:
            print(f"[MIDI] LOAD FAIL : {path.name}")
            print(f"[MIDI] ERROR     : {exc}")
            return False

        absolute_tick = 0
        events = []

        for msg in mido.merge_tracks(midi.tracks):
            absolute_tick += int(msg.time)
            events.append((absolute_tick, msg.copy(time=0)))

        self._song_path = path
        self._events = events
        self._event_index = 0
        self._ticks_per_beat = max(1, int(midi.ticks_per_beat))
        self._total_ticks = max(0, int(absolute_tick))
        self._current_tick = 0
        self._beat_credits = 0
        self._active_notes = {}
        self._notes_silenced_for_pause = False

        self.set_bpm(bpm)
        self._stop_event.clear()

        self._thread = threading.Thread(
            target=self._worker,
            name="MaestroMidiBeatWorker",
            daemon=True,
        )
        self._thread.start()

        print()
        print("=" * 70)
        print("[MIDI] GATED PLAYER READY")
        print(f"FILE         : {path.name}")
        print(f"TICKS/BEAT   : {self._ticks_per_beat}")
        print(f"TOTAL TICKS  : {self._total_ticks}")
        print(f"BPM          : {self._bpm}")
        print("MODE         : PATTERN CHANGE = ONE BEAT")
        print("STATE        : WAIT FIRST BEAT")
        print("=" * 70)

        return True

    def advance_one_beat(self):
        with self._condition:
            if self._thread is None:
                return False

            if not self._thread.is_alive():
                return False

            if self._stop_event.is_set():
                return False

            self._beat_credits += 1
            queued = self._beat_credits
            self._condition.notify_all()

        print(f"[MIDI] BEAT PERMIT +1 (queued={queued})")
        return True

    def set_bpm(self, bpm):
        try:
            value = int(bpm)
        except (TypeError, ValueError):
            return

        if value <= 0:
            return

        with self._condition:
            self._bpm = max(1, min(300, value))

    def set_volume(self, volume):
        try:
            value = int(volume)
        except (TypeError, ValueError):
            return

        self._volume = max(0, min(100, value))
        midi_volume = int(round(self._volume * 127 / 100))

        with self._output_lock:
            if self._output is not None:
                for channel in range(16):
                    self._output.write_short(
                        0xB0 | channel,
                        7,
                        midi_volume,
                    )

    def stop(self):
        self._stop_event.set()

        with self._condition:
            self._beat_credits = 0
            self._condition.notify_all()

        thread = self._thread

        if (
            thread is not None
            and thread.is_alive()
            and thread is not threading.current_thread()
        ):
            thread.join(timeout=1.0)

        self._all_notes_off()

        self._thread = None
        self._events = []
        self._event_index = 0
        self._current_tick = 0
        self._total_ticks = 0
        self._beat_credits = 0
        self._active_notes = {}
        self._notes_silenced_for_pause = False

    def close(self):
        self.stop()

        with self._output_lock:
            if self._output is not None:
                try:
                    self._output.close()
                except Exception:
                    pass
                self._output = None

        if pygame.midi.get_init():
            pygame.midi.quit()

    def _worker(self):
        if self._total_ticks <= 0:
            if not self._stop_event.is_set():
                self.song_finished.emit()
            return

        while not self._stop_event.is_set():
            with self._condition:
                while (
                    self._beat_credits <= 0
                    and not self._stop_event.is_set()
                ):
                    self._condition.wait(timeout=0.1)

                if self._stop_event.is_set():
                    return

                self._beat_credits -= 1

            self._resume_notes_after_pause()

            beat_start = self._current_tick
            beat_end = min(
                beat_start + self._ticks_per_beat,
                self._total_ticks,
            )

            while (
                self._event_index < len(self._events)
                and self._events[self._event_index][0] < beat_end
            ):
                event_tick, msg = self._events[self._event_index]

                if event_tick < self._current_tick:
                    event_tick = self._current_tick

                if not self._wait_ticks(event_tick - self._current_tick):
                    return

                self._current_tick = event_tick
                self._send_message(msg)
                self._event_index += 1

            if not self._wait_ticks(beat_end - self._current_tick):
                return

            self._current_tick = beat_end

            if self._current_tick >= self._total_ticks:
                self._all_notes_off()

                if not self._stop_event.is_set():
                    print()
                    print("=" * 70)
                    print("[MIDI] SONG END REACHED")
                    print(f"FILE         : {self._song_path.name}")
                    print("ACTION       : song_finished")
                    print("=" * 70)
                    self.song_finished.emit()

                return

            with self._condition:
                next_beat_already_permitted = self._beat_credits > 0

            if not next_beat_already_permitted:
                self._silence_notes_for_pause()

                print(
                    f"[MIDI] BEAT DONE tick={self._current_tick} "
                    f"-> WAIT NEXT PATTERN"
                )

    def _wait_ticks(self, ticks):
        remaining_ticks = float(max(0, ticks))

        while (
            remaining_ticks > 0.000001
            and not self._stop_event.is_set()
        ):
            with self._condition:
                bpm = max(1, int(self._bpm))

            ticks_per_second = (
                bpm * self._ticks_per_beat / 60.0
            )

            seconds_left = remaining_ticks / ticks_per_second
            sleep_time = min(0.010, seconds_left)

            if self._stop_event.wait(sleep_time):
                return False

            remaining_ticks -= sleep_time * ticks_per_second

        return not self._stop_event.is_set()

    def _send_message(self, msg):
        if msg.is_meta:
            return

        if msg.type == "note_on":
            key = (int(msg.channel), int(msg.note))

            if int(msg.velocity) == 0:
                self._active_notes.pop(key, None)
            else:
                self._active_notes[key] = int(msg.velocity)

        elif msg.type == "note_off":
            key = (int(msg.channel), int(msg.note))
            self._active_notes.pop(key, None)

        if (
            msg.type == "control_change"
            and int(msg.control) == 7
        ):
            msg = msg.copy(
                value=max(
                    0,
                    min(
                        127,
                        int(round(int(msg.value) * self._volume / 100)),
                    ),
                )
            )

        raw = msg.bytes()

        with self._output_lock:
            if self._output is None:
                return

            if msg.type == "sysex":
                try:
                    self._output.write_sys_ex(
                        pygame.midi.time(),
                        raw,
                    )
                except Exception:
                    pass
                return

            try:
                if len(raw) == 1:
                    self._output.write_short(raw[0])
                elif len(raw) == 2:
                    self._output.write_short(raw[0], raw[1])
                else:
                    self._output.write_short(raw[0], raw[1], raw[2])
            except Exception as exc:
                print(f"[MIDI] OUTPUT ERROR : {exc}")

    def _silence_notes_for_pause(self):
        if not self._active_notes:
            self._notes_silenced_for_pause = False
            return

        with self._output_lock:
            if self._output is not None:
                for (channel, note), _velocity in list(
                    self._active_notes.items()
                ):
                    self._output.write_short(
                        0x80 | channel,
                        note,
                        0,
                    )

        self._notes_silenced_for_pause = True

    def _resume_notes_after_pause(self):
        if not self._notes_silenced_for_pause:
            return

        with self._output_lock:
            if self._output is not None:
                for (channel, note), velocity in list(
                    self._active_notes.items()
                ):
                    self._output.write_short(
                        0x90 | channel,
                        note,
                        max(1, min(127, int(velocity))),
                    )

        self._notes_silenced_for_pause = False

    def _all_notes_off(self):
        with self._output_lock:
            if self._output is not None:
                for channel in range(16):
                    self._output.write_short(
                        0xB0 | channel,
                        123,
                        0,
                    )
                    self._output.write_short(
                        0xB0 | channel,
                        120,
                        0,
                    )

        self._active_notes = {}
        self._notes_silenced_for_pause = False
