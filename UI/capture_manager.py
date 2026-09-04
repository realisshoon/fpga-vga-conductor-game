import sys
from typing import Iterable, Optional

import cv2

from PySide6.QtCore import QObject, QTimer
from PySide6.QtGui import QImage


class CaptureManager(QObject):
    """
    VGA capture board manager.

    CAPTURE ON
        - A capture device is open.
        - Real frames are arriving.
        - Frames are sent to StageWidget.set_video_frame().

    CAPTURE OFF
        - No capture device is available, or frames were lost.
        - StageWidget.set_capture_state(False, ...) clears only the
          real frame.
        - UART/MOCK tracking continues.

    Device selection
    ----------------
    1) device_index is given -> use that index directly.
    2) Otherwise try DirectShow name enumeration with pygrabber.
    3) Prefer names matching preferred_name_keywords.
    4) Reject obvious webcam/virtual-camera names.
    5) Optional unnamed index probing is controlled by
       allow_unnamed_fallback.

    Hot-plug
    --------
    While CAPTURE OFF, the manager re-scans periodically.
    """

    def __init__(
        self,
        window,
        device_index: Optional[int] = None,
        width: int = 640,
        height: int = 480,
        fps: int = 30,
        scan_max_index: int = 8,
        allow_unnamed_fallback: bool = False,
        preferred_name_keywords: Iterable[str] = (),
        reject_name_keywords: Iterable[str] = (),
        parent=None,
    ):
        super().__init__(parent)

        self.window = window

        self.requested_device_index = device_index
        self.width = int(width)
        self.height = int(height)
        self.fps = int(fps)
        self.scan_max_index = max(
            1,
            int(scan_max_index),
        )
        self.allow_unnamed_fallback = bool(
            allow_unnamed_fallback
        )

        self.preferred_name_keywords = tuple(
            str(item).lower()
            for item in preferred_name_keywords
        )

        self.reject_name_keywords = tuple(
            str(item).lower()
            for item in reject_name_keywords
        )

        self.capture = None
        self.active_index = None
        self.active_name = ""

        self.capture_active = False
        self.consecutive_read_failures = 0
        self.max_read_failures = 12

        self._device_names = []
        self._pygrabber_available = False

        interval_ms = max(
            10,
            int(round(1000 / max(1, self.fps))),
        )

        self.frame_timer = QTimer(self)
        self.frame_timer.setInterval(interval_ms)
        self.frame_timer.timeout.connect(
            self.update_frame
        )
        self.frame_timer.start()

        self.rescan_timer = QTimer(self)
        self.rescan_timer.setInterval(2000)
        self.rescan_timer.timeout.connect(
            self.ensure_connected
        )
        self.rescan_timer.start()

        self._set_ui_capture_state(
            False,
            "",
        )

        print()
        print("=" * 70)
        print("[CAPTURE] MANAGER START")
        print(
            f"TARGET       : "
            f"{self.width} x {self.height} "
            f"@ {self.fps} fps"
        )
        print(
            "DEVICE INDEX : "
            + (
                "AUTO"
                if self.requested_device_index is None
                else str(self.requested_device_index)
            )
        )
        print("=" * 70)

        self.ensure_connected()

    # ==================================================
    # DEVICE ENUMERATION
    # ==================================================

    def _enumerate_device_names(self):
        names = []

        if not sys.platform.startswith("win"):
            self._device_names = names
            return names

        try:
            from pygrabber.dshow_graph import FilterGraph

            graph = FilterGraph()
            names = list(graph.get_input_devices())
            self._pygrabber_available = True

        except Exception:
            self._pygrabber_available = False
            names = []

        self._device_names = names
        return names

    def _name_score(self, name):
        lower = str(name).lower()

        if any(
            keyword in lower
            for keyword in self.reject_name_keywords
        ):
            return -1000

        score = 0

        for keyword in self.preferred_name_keywords:
            if keyword in lower:
                score += 10

        return score

    def _candidate_indices(self):
        if self.requested_device_index is not None:
            index = int(
                self.requested_device_index
            )
            return [
                (
                    index,
                    f"VIDEO DEVICE {index}",
                )
            ]

        names = self._enumerate_device_names()

        if names:
            ranked = []

            for index, name in enumerate(names):
                score = self._name_score(name)

                if score <= -1000:
                    continue

                ranked.append(
                    (
                        score,
                        index,
                        name,
                    )
                )

            ranked.sort(
                key=lambda item: (
                    -item[0],
                    item[1],
                )
            )

            matched = [
                (
                    index,
                    name,
                )
                for score, index, name in ranked
                if score > 0
            ]

            if matched:
                print()
                print("[CAPTURE] CANDIDATES")
                for index, name in matched:
                    print(
                        f"  [{index}] {name}"
                    )
                return matched

            print()
            print("[CAPTURE] DEVICE NAMES FOUND")
            for index, name in enumerate(names):
                print(
                    f"  [{index}] {name}"
                )

            print(
                "[CAPTURE] "
                "NO CAPTURE-LIKE NAME MATCH"
            )
            print(
                "[CAPTURE] "
                "Set CAPTURE_DEVICE_INDEX manually "
                "or add a keyword to CAPTURE_NAME_HINTS."
            )
            return []

        if not self.allow_unnamed_fallback:
            print()
            print(
                "[CAPTURE] "
                "DIRECTSHOW NAME ENUMERATION UNAVAILABLE"
            )
            print(
                "[CAPTURE] "
                "SAFE AUTO MODE -> CAPTURE OFF"
            )
            print(
                "[CAPTURE] "
                "Install pygrabber for name-based auto detect, "
                "set CAPTURE_DEVICE_INDEX manually, or enable "
                "CAPTURE_ALLOW_INDEX_FALLBACK."
            )
            return []

        return [
            (
                index,
                f"VIDEO DEVICE {index}",
            )
            for index in range(
                self.scan_max_index
            )
        ]

    # ==================================================
    # OPEN / CLOSE
    # ==================================================

    def _backend(self):
        if sys.platform.startswith("win"):
            return cv2.CAP_DSHOW

        return cv2.CAP_ANY

    def _open_index(self, index, name):
        backend = self._backend()

        cap = cv2.VideoCapture(
            int(index),
            backend,
        )

        if not cap.isOpened():
            cap.release()
            return False

        cap.set(
            cv2.CAP_PROP_FRAME_WIDTH,
            self.width,
        )
        cap.set(
            cv2.CAP_PROP_FRAME_HEIGHT,
            self.height,
        )
        cap.set(
            cv2.CAP_PROP_FPS,
            self.fps,
        )

        try:
            cap.set(
                cv2.CAP_PROP_BUFFERSIZE,
                1,
            )
        except Exception:
            pass

        # Opening alone is insufficient.
        # We require a real frame before CAPTURE ON.
        ret, frame = cap.read()

        if (
            not ret
            or
            frame is None
            or
            frame.size == 0
        ):
            cap.release()
            return False

        self.capture = cap
        self.active_index = int(index)
        self.active_name = str(name)
        self.consecutive_read_failures = 0

        self._publish_frame(frame)
        self._set_ui_capture_state(
            True,
            self.active_name,
        )

        print()
        print("=" * 70)
        print("[CAPTURE] CONNECT SUCCESS")
        print(
            f"INDEX        : "
            f"{self.active_index}"
        )
        print(
            f"DEVICE       : "
            f"{self.active_name}"
        )
        print(
            "FRAME        : "
            f"{frame.shape[1]} x "
            f"{frame.shape[0]}"
        )
        print("MODE         : CAPTURE ON")
        print("=" * 70)

        return True

    def ensure_connected(self):
        if (
            self.capture is not None
            and
            self.capture.isOpened()
            and
            self.capture_active
        ):
            return

        self._release_capture(log=False)

        candidates = self._candidate_indices()

        for index, name in candidates:
            if self._open_index(
                index,
                name,
            ):
                return

        self._set_ui_capture_state(
            False,
            "",
        )

    def _release_capture(self, log=True):
        had_capture = (
            self.capture is not None
        )

        if self.capture is not None:
            try:
                self.capture.release()
            except Exception:
                pass

        self.capture = None
        self.active_index = None
        self.active_name = ""
        self.consecutive_read_failures = 0

        if had_capture and log:
            print()
            print(
                "[CAPTURE] "
                "DISCONNECTED -> CAPTURE OFF"
            )

    # ==================================================
    # FRAME UPDATE
    # ==================================================

    def update_frame(self):
        if (
            self.capture is None
            or
            not self.capture.isOpened()
        ):
            return

        ret, frame = self.capture.read()

        if (
            not ret
            or
            frame is None
            or
            frame.size == 0
        ):
            self.consecutive_read_failures += 1

            if (
                self.consecutive_read_failures
                >= self.max_read_failures
            ):
                print()
                print(
                    "[CAPTURE] FRAME LOST -> "
                    "CAPTURE OFF / UART TRACKING"
                )

                self._release_capture(
                    log=False
                )
                self._set_ui_capture_state(
                    False,
                    "",
                )

            return

        self.consecutive_read_failures = 0

        if not self.capture_active:
            self._set_ui_capture_state(
                True,
                self.active_name,
            )

        self._publish_frame(frame)

    def _publish_frame(self, frame):
        frame_rgb = cv2.cvtColor(
            frame,
            cv2.COLOR_BGR2RGB,
        )

        height, width, channels = (
            frame_rgb.shape
        )
        bytes_per_line = (
            channels * width
        )

        image = QImage(
            frame_rgb.data,
            width,
            height,
            bytes_per_line,
            QImage.Format_RGB888,
        ).copy()

        self.window.stage.set_video_frame(
            image
        )

    # ==================================================
    # UI STATE
    # ==================================================

    def _set_ui_capture_state(
        self,
        active,
        device_name,
    ):
        active = bool(active)
        device_name = str(
            device_name or ""
        )

        previous_active = (
            self.capture_active
        )
        previous_name = (
            self.active_name
        )

        self.capture_active = active

        if active:
            self.active_name = device_name
        elif self.capture is None:
            self.active_name = ""

        # This method EXISTS in the matching ui.py.
        self.window.stage.set_capture_state(
            active,
            device_name,
        )

        changed = (
            previous_active != active
            or
            previous_name != self.active_name
        )

        if changed:
            print()
            print(
                "[CAPTURE] STATE = "
                + (
                    f"ON ({device_name})"
                    if active
                    else "OFF"
                )
            )

    # ==================================================
    # CLOSE
    # ==================================================

    def close(self):
        if self.frame_timer.isActive():
            self.frame_timer.stop()

        if self.rescan_timer.isActive():
            self.rescan_timer.stop()

        self._release_capture(
            log=False
        )
        self._set_ui_capture_state(
            False,
            "",
        )

        print(
            "[CAPTURE] MANAGER CLOSE"
        )
