from math import sin, cos, radians

from PySide6.QtCore import (
    Qt,
    Signal,
    QRectF,
    QPointF,
    QTimer,
)

from PySide6.QtGui import (
    QColor,
    QFont,
    QPainter,
    QPen,
    QBrush,
    QLinearGradient,
    QRadialGradient,
    QImage,
    QPainterPath,
    QPolygonF,
)

from PySide6.QtWidgets import (
    QMainWindow,
    QWidget,
    QLabel,
    QPushButton,
    QComboBox,
    QVBoxLayout,
    QHBoxLayout,
    QFrame,
    QSizePolicy,
    QStackedWidget,
    QSlider,
)

try:
    from protocol import (
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

except ImportError:
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
        PATTERN_READY: "READY",
        PATTERN_1: "PATTERN_1",
        PATTERN_2: "PATTERN_2",
        PATTERN_3: "PATTERN_3",
        PATTERN_4: "PATTERN_4",
        PATTERN_STOP: "STOP",
    }


# =========================================================
# TITLE SCREEN
# =========================================================

class TitleScreenWidget(QWidget):

    start_requested = Signal()

    def __init__(self):
        super().__init__()

        self.start_button = QPushButton("START", self)
        self.start_button.setCursor(Qt.PointingHandCursor)
        self.start_button.clicked.connect(self.start_requested.emit)

        self.start_button.setStyleSheet("""
        QPushButton {
            color: #14202A;
            background-color: #E2B75B;
            border: 2px solid #F8D990;
            border-radius: 25px;
            font-size: 18px;
            font-weight: 900;
            letter-spacing: 3px;
            padding: 12px 42px;
        }

        QPushButton:hover {
            background-color: #F0CA71;
            border-color: #FFF0BC;
        }

        QPushButton:pressed {
            background-color: #B98B3D;
        }
        """)

    def resizeEvent(self, event):
        bw = 220
        bh = 58

        x = int((self.width() - bw) / 2)
        y = int(self.height() * 0.80)

        self.start_button.setGeometry(
            x,
            y,
            bw,
            bh
        )

        super().resizeEvent(event)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        w = self.width()
        h = self.height()

        self.draw_background(painter, w, h)
        self.draw_left_scene(painter, w, h)
        self.draw_right_scene(painter, w, h)
        self.draw_conductor(painter, w, h)
        self.draw_title(painter, w, h)
        self.draw_border(painter, w, h)

    def draw_background(self, painter, w, h):
        gradient = QLinearGradient(0, 0, w, 0)

        gradient.setColorAt(0.0, QColor("#151019"))
        gradient.setColorAt(0.28, QColor("#171525"))
        gradient.setColorAt(0.50, QColor("#233747"))
        gradient.setColorAt(0.72, QColor("#205261"))
        gradient.setColorAt(1.0, QColor("#0D2740"))

        painter.fillRect(
            self.rect(),
            QBrush(gradient)
        )

        left = QRadialGradient(
            QPointF(w * 0.18, h * 0.43),
            w * 0.28
        )

        left.setColorAt(
            0.0,
            QColor(116, 43, 49, 75)
        )

        left.setColorAt(
            1.0,
            QColor(0, 0, 0, 0)
        )

        painter.fillRect(
            self.rect(),
            QBrush(left)
        )

        right = QRadialGradient(
            QPointF(w * 0.82, h * 0.43),
            w * 0.28
        )

        right.setColorAt(
            0.0,
            QColor(89, 167, 157, 65)
        )

        right.setColorAt(
            1.0,
            QColor(0, 0, 0, 0)
        )

        painter.fillRect(
            self.rect(),
            QBrush(right)
        )

        center = QRadialGradient(
            QPointF(w / 2, h * 0.44),
            w * 0.25
        )

        center.setColorAt(
            0.0,
            QColor(235, 196, 107, 46)
        )

        center.setColorAt(
            1.0,
            QColor(0, 0, 0, 0)
        )

        painter.fillRect(
            self.rect(),
            QBrush(center)
        )

    def draw_left_scene(self, painter, w, h):
        painter.save()

        font = QFont("Segoe UI")
        font.setPointSize(10)
        font.setBold(True)

        painter.setFont(font)
        painter.setPen(
            QColor(220, 144, 126, 140)
        )

        painter.drawText(
            QRectF(
                w * 0.05,
                h * 0.14,
                w * 0.24,
                30
            ),
            Qt.AlignCenter,
            "THE AUDIENCE LEAVES"
        )

        self.draw_title_person(
            painter,
            w * 0.10,
            h * 0.43,
            1.0,
            False
        )

        self.draw_title_person(
            painter,
            w * 0.19,
            h * 0.54,
            1.1,
            False
        )

        self.draw_title_person(
            painter,
            w * 0.27,
            h * 0.38,
            0.95,
            False
        )

        painter.restore()

    def draw_right_scene(self, painter, w, h):
        painter.save()

        font = QFont("Segoe UI")
        font.setPointSize(10)
        font.setBold(True)

        painter.setFont(font)
        painter.setPen(
            QColor(181, 231, 216, 150)
        )

        painter.drawText(
            QRectF(
                w * 0.71,
                h * 0.14,
                w * 0.24,
                30
            ),
            Qt.AlignCenter,
            "THE CROWD CHEERS"
        )

        self.draw_title_person(
            painter,
            w * 0.75,
            h * 0.50,
            1.05,
            True
        )

        self.draw_title_person(
            painter,
            w * 0.85,
            h * 0.37,
            0.95,
            True
        )

        self.draw_title_person(
            painter,
            w * 0.84,
            h * 0.61,
            1.10,
            True
        )

        painter.restore()

    def draw_title_person(
        self,
        painter,
        x,
        y,
        scale,
        cheering
    ):
        painter.save()

        skin = QColor(221, 181, 139)
        body = QColor(47, 66, 88)

        painter.setPen(Qt.NoPen)

        painter.setBrush(skin)
        painter.drawEllipse(
            QRectF(
                x - 8 * scale,
                y - 8 * scale,
                16 * scale,
                16 * scale
            )
        )

        painter.setBrush(body)
        painter.drawRoundedRect(
            QRectF(
                x - 10 * scale,
                y + 8 * scale,
                20 * scale,
                30 * scale
            ),
            5,
            5
        )

        arm = QPen(
            skin,
            3 * scale
        )
        arm.setCapStyle(Qt.RoundCap)

        painter.setPen(arm)

        if cheering:
            painter.drawLine(
                QPointF(
                    x - 6 * scale,
                    y + 15 * scale
                ),
                QPointF(
                    x - 18 * scale,
                    y - 13 * scale
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6 * scale,
                    y + 15 * scale
                ),
                QPointF(
                    x + 18 * scale,
                    y - 13 * scale
                )
            )

        else:
            painter.drawLine(
                QPointF(
                    x - 6 * scale,
                    y + 15 * scale
                ),
                QPointF(
                    x - 19 * scale,
                    y + 30 * scale
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6 * scale,
                    y + 15 * scale
                ),
                QPointF(
                    x + 13 * scale,
                    y + 34 * scale
                )
            )

        painter.restore()

    def draw_conductor(self, painter, w, h):
        painter.save()

        x = w / 2
        y = h * 0.50

        skin = QColor(229, 184, 134)
        tux = QColor(22, 29, 46)
        red = QColor(217, 82, 60)
        white = QColor(244, 241, 233)

        painter.setPen(Qt.NoPen)

        painter.setBrush(
            QColor(0, 0, 0, 75)
        )

        painter.drawEllipse(
            QRectF(
                x - 55,
                y + 178,
                110,
                16
            )
        )

        painter.setBrush(skin)

        painter.drawEllipse(
            QRectF(
                x - 18,
                y - 66,
                36,
                36
            )
        )

        painter.setBrush(
            QColor(28, 27, 30)
        )

        painter.drawPie(
            QRectF(
                x - 18,
                y - 67,
                36,
                23
            ),
            0,
            180 * 16
        )

        painter.setBrush(tux)

        body = QPolygonF(
            [
                QPointF(
                    x - 40,
                    y - 24
                ),
                QPointF(
                    x + 40,
                    y - 24
                ),
                QPointF(
                    x + 25,
                    y + 115
                ),
                QPointF(
                    x - 25,
                    y + 115
                ),
            ]
        )

        painter.drawPolygon(body)

        painter.setBrush(white)

        painter.drawPolygon(
            QPolygonF(
                [
                    QPointF(
                        x - 11,
                        y - 20
                    ),
                    QPointF(
                        x + 11,
                        y - 20
                    ),
                    QPointF(
                        x + 4,
                        y + 53
                    ),
                    QPointF(
                        x - 4,
                        y + 53
                    ),
                ]
            )
        )

        sleeve = QPen(red, 16)
        sleeve.setCapStyle(Qt.RoundCap)

        painter.setPen(sleeve)

        painter.drawLine(
            QPointF(
                x - 15,
                y
            ),
            QPointF(
                x - 88,
                y - 48
            )
        )

        painter.drawLine(
            QPointF(
                x + 15,
                y
            ),
            QPointF(
                x + 91,
                y - 30
            )
        )

        hand_pen = QPen(skin, 9)
        hand_pen.setCapStyle(Qt.RoundCap)

        painter.setPen(hand_pen)

        painter.drawLine(
            QPointF(
                x - 88,
                y - 48
            ),
            QPointF(
                x - 105,
                y - 59
            )
        )

        painter.drawLine(
            QPointF(
                x + 91,
                y - 30
            ),
            QPointF(
                x + 106,
                y - 38
            )
        )

        painter.setPen(
            QPen(
                QColor(250, 239, 205),
                3
            )
        )

        painter.drawLine(
            QPointF(
                x + 107,
                y - 38
            ),
            QPointF(
                x + 144,
                y - 90
            )
        )

        painter.setPen(
            QPen(
                tux,
                10
            )
        )

        painter.drawLine(
            QPointF(
                x - 10,
                y + 110
            ),
            QPointF(
                x - 18,
                y + 175
            )
        )

        painter.drawLine(
            QPointF(
                x + 10,
                y + 110
            ),
            QPointF(
                x + 18,
                y + 175
            )
        )

        painter.restore()

    def draw_title(self, painter, w, h):
        painter.save()

        small = QFont("Segoe UI")
        small.setPointSize(10)
        small.setBold(True)

        small.setLetterSpacing(
            QFont.SpacingType.AbsoluteSpacing,
            4
        )

        painter.setFont(small)
        painter.setPen(
            QColor(236, 199, 118)
        )

        painter.drawText(
            QRectF(
                0,
                h * 0.07,
                w,
                28
            ),
            Qt.AlignCenter,
            "VGA CONDUCTOR SIMULATION"
        )

        title = QFont("Segoe UI")

        title.setPointSize(
            max(
                54,
                int(h * 0.085)
            )
        )

        title.setBold(True)

        title.setLetterSpacing(
            QFont.SpacingType.AbsoluteSpacing,
            7
        )

        painter.setFont(title)
        painter.setPen(
            QColor(250, 245, 225)
        )

        painter.drawText(
            QRectF(
                0,
                h * 0.14,
                w,
                h * 0.12
            ),
            Qt.AlignCenter,
            "MAESTRO"
        )

        sub = QFont("Segoe UI")
        sub.setPointSize(12)
        sub.setBold(True)

        painter.setFont(sub)
        painter.setPen(
            QColor(230, 190, 96)
        )

        painter.drawText(
            QRectF(
                0,
                h * 0.26,
                w,
                30
            ),
            Qt.AlignCenter,
            "BECOME THE CONDUCTOR"
        )

        painter.restore()

    def draw_border(self, painter, w, h):
        painter.save()

        painter.setBrush(Qt.NoBrush)

        painter.setPen(
            QPen(
                QColor(
                    221,
                    174,
                    79,
                    120
                ),
                2
            )
        )

        painter.drawRoundedRect(
            QRectF(
                24,
                24,
                w - 48,
                h - 48
            ),
            18,
            18
        )

        painter.restore()


# =========================================================
# VOLUME
# =========================================================

class VolumeBar(QWidget):

    def __init__(self):
        super().__init__()

        self.volume = 50

        self.setMinimumWidth(120)
        self.setMaximumWidth(145)

    def set_volume(self, value):
        self.volume = max(
            0,
            min(
                100,
                int(value)
            )
        )

        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)

        painter.setRenderHint(
            QPainter.Antialiasing
        )

        w = self.width()
        h = self.height()

        font = QFont("Segoe UI")
        font.setPointSize(10)
        font.setBold(True)

        painter.setFont(font)
        painter.setPen(
            QColor("#C8CBD1")
        )

        painter.drawText(
            QRectF(
                0,
                18,
                w,
                30
            ),
            Qt.AlignCenter,
            "VOLUME"
        )

        bw = 30
        bh = max(
            150,
            h - 150
        )

        bx = (
            w - bw
        ) / 2

        by = 65

        painter.setBrush(
            QColor("#0B0D12")
        )

        painter.setPen(
            QPen(
                QColor("#424650"),
                2
            )
        )

        painter.drawRoundedRect(
            QRectF(
                bx,
                by,
                bw,
                bh
            ),
            10,
            10
        )

        fill = (
            bh
            * self.volume
            / 100
        )

        gradient = QLinearGradient(
            0,
            by + bh,
            0,
            by
        )

        gradient.setColorAt(
            0.0,
            QColor("#41DA88")
        )

        gradient.setColorAt(
            0.62,
            QColor("#D8D75C")
        )

        gradient.setColorAt(
            1.0,
            QColor("#F47566")
        )

        painter.setPen(Qt.NoPen)
        painter.setBrush(
            QBrush(gradient)
        )

        if fill > 4:
            painter.drawRoundedRect(
                QRectF(
                    bx + 4,
                    by + bh - fill + 4,
                    bw - 8,
                    max(
                        2,
                        fill - 8
                    )
                ),
                7,
                7
            )

        value_font = QFont("Segoe UI")
        value_font.setPointSize(15)
        value_font.setBold(True)

        painter.setFont(value_font)
        painter.setPen(
            QColor("#F6F7F8")
        )

        painter.drawText(
            QRectF(
                0,
                by + bh + 20,
                w,
                40
            ),
            Qt.AlignCenter,
            f"{self.volume}%"
        )


# =========================================================
# INFO CARD
# =========================================================

class InfoCard(QFrame):

    def __init__(
        self,
        title,
        value,
        unit=""
    ):
        super().__init__()

        self.setObjectName(
            "info_card"
        )

        self.title_label = QLabel(title)
        self.value_label = QLabel(str(value))
        self.unit_label = QLabel(unit)

        self.title_label.setObjectName(
            "info_title"
        )

        self.value_label.setObjectName(
            "info_value"
        )

        self.unit_label.setObjectName(
            "info_unit"
        )

        for label in (
            self.title_label,
            self.value_label,
            self.unit_label
        ):
            label.setAlignment(
                Qt.AlignCenter
            )

        layout = QVBoxLayout()

        layout.setContentsMargins(
            10,
            10,
            10,
            10
        )

        layout.setSpacing(2)

        layout.addWidget(
            self.title_label
        )

        layout.addWidget(
            self.value_label
        )

        if unit:
            layout.addWidget(
                self.unit_label
            )

        self.setLayout(layout)

    def set_value(self, value):
        self.value_label.setText(
            str(value)
        )


# =========================================================
# STAGE
# =========================================================

class StageWidget(QWidget):

    AUDIENCE_LIFT_RATIO = 0.08

    def __init__(self):
        super().__init__()

        self.scene = "MAIN"

        self.score = 5
        self.pattern = PATTERN_IDLE
        self.speed = 120

        self.red_x = 1023
        self.red_y = 1023

        self.green_x = 1023
        self.green_y = 1023

        self.final_score = 50

        self.video_frame = None

        # Capture board state only. Existing UI drawing is preserved.
        self.capture_active = False
        self.capture_device_name = ""

        # ==================================================
        # SEATED AUDIENCE
        # ==================================================

        self.max_seated = 52
        self.target_seated = 0

        self.seated_presence = [
            0.0
            for _ in range(
                self.max_seated
            )
        ]

        # ==================================================
        # STANDING AUDIENCE
        # ==================================================

        self.max_standing = 20
        self.target_standing = 0

        self.standing_presence = [
            0.0
            for _ in range(
                self.max_standing
            )
        ]

        # ==================================================
        # ORCHESTRA
        # ==================================================

        self.orchestra_count = 14

        self.orchestra_instrument_progress = [
            1.0
            for _ in range(
                self.orchestra_count
            )
        ]

        # ==================================================
        # CURTAIN
        # ==================================================

        self.curtain_progress = 1.0
        self.curtain_target = 1.0

        self.animation_phase = False

        self.animation_timer = QTimer(self)

        self.animation_timer.setInterval(
            70
        )

        self.animation_timer.timeout.connect(
            self.animate
        )

        self.animation_timer.start()

        self.setMinimumSize(
            720,
            520
        )

        self.setSizePolicy(
            QSizePolicy.Expanding,
            QSizePolicy.Expanding
        )

    # ==================================================
    # START / STOP ANIMATION
    # ==================================================

    def start_animation(self):
        if not self.animation_timer.isActive():
            self.animation_timer.start()

    def stop_animation(self):
        self.animation_timer.stop()

    # ==================================================
    # SCORE → AUDIENCE
    #
    # 50점 = 좌석 52명
    #
    # 60~100점
    # 좌석 52명 유지
    # 펜스 뒤 standing 증가
    #
    # 40점 이하
    # standing 없음
    # 4열 → 3열 → 2열 → 1열 순으로 퇴장
    #
    # 의자는 항상 52개 유지
    # ==================================================

    def score_to_targets(self, score):
        score = max(
            0,
            min(
                10,
                int(score)
            )
        )

        seated = {
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

        standing = {
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
            seated[score],
            standing[score]
        )

    def update_audience_targets(self):
        (
            self.target_seated,
            self.target_standing
        ) = self.score_to_targets(
            self.score
        )

    # ==================================================
    # SCENE
    # ==================================================

    def set_scene(self, scene):
        self.scene = scene

        if scene in (
            "MAIN",
            "MENU"
        ):
            self.target_seated = 0
            self.target_standing = 0

            self.close_curtain()

        elif scene == "READY":
            self.score = 5

            self.target_seated = 52
            self.target_standing = 0

            self.open_curtain()

        elif scene == "PLAYING":
            self.open_curtain()
            self.update_audience_targets()

        elif scene == "RESULT":
            self.update_audience_targets()

        self.update()

    def set_fpga_data(self, data):
        self.score = max(
            0,
            min(
                10,
                int(
                    data["score"]
                )
            )
        )

        self.pattern = int(
            data["pattern"]
        )

        self.speed = int(
            data["speed"]
        )

        self.red_x = int(
            data["red_x"]
        )

        self.red_y = int(
            data["red_y"]
        )

        self.green_x = int(
            data["green_x"]
        )

        self.green_y = int(
            data["green_y"]
        )

        if self.scene in (
            "PLAYING",
            "RESULT"
        ):
            self.update_audience_targets()

        self.update()

    def set_final_score(self, score):
        self.final_score = (
            int(score)
            * 10
        )

        self.update()

    def set_video_frame(
        self,
        image: QImage
    ):
        self.video_frame = image
        self.update()

    def set_capture_state(
        self,
        active,
        device_name=""
    ):
        self.capture_active = bool(active)
        self.capture_device_name = str(
            device_name or ""
        )

        if not self.capture_active:
            self.video_frame = None

        self.update()

    def open_curtain(self):
        self.curtain_target = 0.0

    def close_curtain(self):
        self.curtain_target = 1.0

    # ==================================================
    # ANIMATE
    # ==================================================

    def animate(self):
        changed = False

        if (
            self.curtain_progress
            < self.curtain_target
        ):
            self.curtain_progress = min(
                self.curtain_target,
                self.curtain_progress
                + 0.055
            )

            changed = True

        elif (
            self.curtain_progress
            > self.curtain_target
        ):
            self.curtain_progress = max(
                self.curtain_target,
                self.curtain_progress
                - 0.055
            )

            changed = True

        # seated
        for i in range(
            self.max_seated
        ):
            target = (
                1.0
                if i < self.target_seated
                else 0.0
            )

            current = (
                self.seated_presence[i]
            )

            if current < target:
                self.seated_presence[i] = min(
                    target,
                    current + 0.07
                )

                changed = True

            elif current > target:
                self.seated_presence[i] = max(
                    target,
                    current - 0.07
                )

                changed = True

        # standing
        for i in range(
            self.max_standing
        ):
            target = (
                1.0
                if i < self.target_standing
                else 0.0
            )

            current = (
                self.standing_presence[i]
            )

            if current < target:
                self.standing_presence[i] = min(
                    target,
                    current + 0.07
                )

                changed = True

            elif current > target:
                self.standing_presence[i] = max(
                    target,
                    current - 0.07
                )

                changed = True

        # orchestra instrument drop
        if (
            self.scene == "PLAYING"
            and
            self.score <= 2
        ):
            instrument_target = 0.0

        else:
            instrument_target = 1.0

        for i in range(
            self.orchestra_count
        ):
            current = (
                self.orchestra_instrument_progress[i]
            )

            if current < instrument_target:
                self.orchestra_instrument_progress[i] = min(
                    instrument_target,
                    current + 0.075
                )

                changed = True

            elif current > instrument_target:
                self.orchestra_instrument_progress[i] = max(
                    instrument_target,
                    current - 0.075
                )

                changed = True

        if self.scene in (
            "READY",
            "PLAYING",
            "RESULT"
        ):
            self.animation_phase = (
                not self.animation_phase
            )

            changed = True

        if changed:
            self.update()

    # ==================================================
    # VGA AREA
    # ==================================================

    def build_video_rect(self, w, h):
        # Large 4:3 VGA viewport.
        #
        # IMPORTANT:
        # - FPGA logical coordinates stay 320 x 240.
        # - Capture input stays 640 x 480.
        # - Only the PC-side rendering rectangle is enlarged.
        # - source_to_screen() keeps RED/GREEN/ZONE alignment.

        max_w = (
            w * 0.72
        )

        max_h = (
            h * 0.58
        )

        video_w = min(
            max_w,
            max_h * 4 / 3
        )

        video_h = (
            video_w * 3 / 4
        )

        return QRectF(
            (
                w - video_w
            ) / 2,
            h * 0.045,
            video_w,
            video_h
        )

    def source_to_screen(
        self,
        rect,
        x,
        y
    ):
        return (
            rect.left()
            + x
            / 320.0
            * rect.width(),

            rect.top()
            + y
            / 240.0
            * rect.height()
        )

    def make_zone(
        self,
        rect,
        x1,
        x2,
        y1,
        y2
    ):
        sx1, sy1 = (
            self.source_to_screen(
                rect,
                x1,
                y1
            )
        )

        sx2, sy2 = (
            self.source_to_screen(
                rect,
                x2,
                y2
            )
        )

        return QRectF(
            sx1,
            sy1,
            sx2 - sx1,
            sy2 - sy1
        )

    def get_zone_items(self, rect):
        return [
            (
                1,
                self.make_zone(
                    rect,
                    140,
                    180,
                    175,
                    239
                )
            ),

            (
                2,
                self.make_zone(
                    rect,
                    75,
                    125,
                    110,
                    160
                )
            ),

            (
                3,
                self.make_zone(
                    rect,
                    195,
                    245,
                    110,
                    160
                )
            ),

            (
                4,
                self.make_zone(
                    rect,
                    140,
                    180,
                    0,
                    60
                )
            ),
        ]

    # ==================================================
    # FAN GEOMETRY
    # ==================================================

    def fan_point(
        self,
        center_x,
        center_y,
        radius_x,
        edge_lift,
        t
    ):
        max_angle = 58.0

        angle = radians(
            t * max_angle
        )

        edge_angle = radians(
            max_angle
        )

        edge_norm = (
            1.0
            - cos(angle)
        ) / (
            1.0
            - cos(edge_angle)
        )

        x = (
            center_x
            + radius_x
            * sin(angle)
        )

        y = (
            center_y
            - edge_lift
            * edge_norm
        )

        return (
            x,
            y
        )

    def get_row_t_values(
        self,
        count
    ):
        if count <= 1:
            return [0.0]

        values = []

        half = (
            count // 2
        )

        gap = 0.10

        for i in range(
            half
        ):
            ratio = (
                i
                / max(
                    1,
                    half - 1
                )
            )

            values.append(
                -1.0
                + ratio
                * (
                    1.0
                    - gap
                )
            )

        for i in range(
            half
        ):
            ratio = (
                i
                / max(
                    1,
                    half - 1
                )
            )

            values.append(
                gap
                + ratio
                * (
                    1.0
                    - gap
                )
            )

        return values

    # ==================================================
    # SEATED FAN
    #
    # row 0 = 1열 = 무대 가장 가까움
    # row 3 = 4열 = 가장 뒤
    #
    # 이번 수정:
    # 전체 좌석을 위로 lift
    # ==================================================

    def get_seated_row_definitions(
        self,
        w,
        h,
        stage_bottom
    ):
        available = max(
            220,
            h - stage_bottom
        )

        lift = (
            available
            * self.AUDIENCE_LIFT_RATIO
        )

        return [
            # 1열
            {
                "row": 0,
                "count": 10,
                "center_y":
                    stage_bottom
                    + available
                    * 0.13
                    - lift,
                "radius_x":
                    w * 0.30,
                "edge_lift":
                    available
                    * 0.050,
                "scale": 0.88,
            },

            # 2열
            {
                "row": 1,
                "count": 12,
                "center_y":
                    stage_bottom
                    + available
                    * 0.28
                    - lift,
                "radius_x":
                    w * 0.37,
                "edge_lift":
                    available
                    * 0.067,
                "scale": 0.97,
            },

            # 3열
            {
                "row": 2,
                "count": 14,
                "center_y":
                    stage_bottom
                    + available
                    * 0.44
                    - lift,
                "radius_x":
                    w * 0.44,
                "edge_lift":
                    available
                    * 0.083,
                "scale": 1.06,
            },

            # 4열
            {
                "row": 3,
                "count": 16,
                "center_y":
                    stage_bottom
                    + available
                    * 0.61
                    - lift,
                "radius_x":
                    w * 0.51,
                "edge_lift":
                    available
                    * 0.100,
                "scale": 1.14,
            },
        ]

    def build_seated_slots(
        self,
        w,
        h,
        stage_bottom
    ):
        slots = []

        center_x = (
            w / 2
        )

        rows = (
            self.get_seated_row_definitions(
                w,
                h,
                stage_bottom
            )
        )

        # ==================================================
        # 중요
        #
        # presence index:
        #
        # 0 ~ 9      = 1열
        # 10 ~ 21    = 2열
        # 22 ~ 35    = 3열
        # 36 ~ 51    = 4열
        #
        # target이 감소하면 높은 index부터 없어지므로
        # 4열 → 3열 → 2열 → 1열 순으로 퇴장.
        # ==================================================

        for row in rows:
            row_slots = []

            for t in (
                self.get_row_t_values(
                    row["count"]
                )
            ):
                x, y = (
                    self.fan_point(
                        center_x,
                        row["center_y"],
                        row["radius_x"],
                        row["edge_lift"],
                        t
                    )
                )

                row_slots.append(
                    {
                        "row": row["row"],
                        "x": x,
                        "y": y,
                        "t": t,
                        "scale": row["scale"],
                    }
                )

            # 같은 열에서는 중앙 좌석을 먼저 유지
            row_slots.sort(
                key=lambda slot:
                    abs(
                        slot["t"]
                    )
            )

            slots.extend(
                row_slots
            )

        return slots

    # ==================================================
    # FENCE
    #
    # 이번 수정:
    # 좌석과 함께 위로 lift
    # ==================================================

    def get_fence_geometry(
        self,
        w,
        h,
        stage_bottom
    ):
        available = max(
            220,
            h - stage_bottom
        )

        lift = (
            available
            * self.AUDIENCE_LIFT_RATIO
        )

        return {
            "center_x":
                w / 2,

            "center_y":
                stage_bottom
                + available
                * 0.735
                - lift,

            "radius_x":
                w * 0.565,

            "edge_lift":
                available
                * 0.115,
        }

    # ==================================================
    # STANDING FAN
    #
    # 이번 수정:
    # 펜스와 함께 위로 lift
    # ==================================================

    def build_standing_slots(
        self,
        w,
        h,
        stage_bottom
    ):
        available = max(
            220,
            h - stage_bottom
        )

        center_x = (
            w / 2
        )

        lift = (
            available
            * self.AUDIENCE_LIFT_RATIO
        )

        rows = [
            {
                "count": 10,
                "center_y":
                    stage_bottom
                    + available
                    * 0.84
                    - lift,
                "radius_x":
                    w * 0.53,
                "edge_lift":
                    available
                    * 0.095,
                "scale": 0.82,
            },

            {
                "count": 10,
                "center_y":
                    stage_bottom
                    + available
                    * 0.96
                    - lift,
                "radius_x":
                    w * 0.59,
                "edge_lift":
                    available
                    * 0.110,
                "scale": 0.88,
            },
        ]

        slots = []

        for row_index, row in enumerate(
            rows
        ):
            row_slots = []

            for t in (
                self.get_row_t_values(
                    row["count"]
                )
            ):
                x, y = (
                    self.fan_point(
                        center_x,
                        row["center_y"],
                        row["radius_x"],
                        row["edge_lift"],
                        t
                    )
                )

                row_slots.append(
                    {
                        "row": row_index,
                        "x": x,
                        "y": y,
                        "t": t,
                        "scale": row["scale"],
                    }
                )

            row_slots.sort(
                key=lambda slot:
                    abs(
                        slot["t"]
                    )
            )

            slots.extend(
                row_slots
            )

        return slots

    # ==================================================
    # PAINT
    # ==================================================

    def paintEvent(self, event):
        painter = QPainter(self)

        painter.setRenderHint(
            QPainter.Antialiasing
        )

        w = self.width()
        h = self.height()

        self.draw_background(
            painter,
            w,
            h
        )

        self.draw_music_watermark(
            painter,
            w,
            h
        )

        video_rect = (
            self.build_video_rect(
                w,
                h
            )
        )

        self.draw_orchestra_pits(
            painter,
            w,
            video_rect
        )

        self.draw_orchestra(
            painter,
            w,
            video_rect
        )

        self.draw_video(
            painter,
            video_rect
        )

        self.draw_floor(
            painter,
            w,
            h,
            video_rect
        )

        self.draw_seated_audience(
            painter,
            w,
            h,
            video_rect.bottom()
        )

        self.draw_fan_fence(
            painter,
            w,
            h,
            video_rect.bottom()
        )

        self.draw_standing_audience(
            painter,
            w,
            h,
            video_rect.bottom()
        )

        self.draw_curtain(
            painter,
            video_rect
        )

        self.draw_scene_text(
            painter,
            video_rect
        )

    # ==================================================
    # BACKGROUND
    # ==================================================

    def draw_background(
        self,
        painter,
        w,
        h
    ):
        gradient = QLinearGradient(
            0,
            0,
            0,
            h
        )

        gradient.setColorAt(
            0.0,
            QColor("#050609")
        )

        gradient.setColorAt(
            0.45,
            QColor("#111018")
        )

        gradient.setColorAt(
            1.0,
            QColor("#030405")
        )

        painter.fillRect(
            self.rect(),
            QBrush(gradient)
        )

        painter.setPen(
            QPen(
                QColor(
                    175,
                    132,
                    67,
                    110
                ),
                2
            )
        )

        painter.drawLine(
            QPointF(
                w * 0.10,
                12
            ),
            QPointF(
                w * 0.90,
                12
            )
        )

    def draw_music_watermark(
        self,
        painter,
        w,
        h
    ):
        painter.save()

        font = QFont(
            "Segoe UI Symbol"
        )

        font.setPointSize(
            max(
                28,
                int(
                    h * 0.065
                )
            )
        )

        painter.setFont(font)

        painter.setPen(
            QColor(
                205,
                176,
                125,
                18
            )
        )

        painter.drawText(
            QRectF(
                0,
                h * 0.12,
                w * 0.30,
                h * 0.20
            ),
            Qt.AlignCenter,
            "♪  ♫"
        )

        painter.drawText(
            QRectF(
                w * 0.70,
                h * 0.12,
                w * 0.30,
                h * 0.20
            ),
            Qt.AlignCenter,
            "♫  ♪"
        )

        painter.restore()

    # ==================================================
    # ORCHESTRA
    # ==================================================

    def get_orchestra_members(
        self,
        w,
        rect
    ):
        left_w = max(
            110,
            rect.left() - 38
        )

        right_start = (
            rect.right()
            + 22
        )

        right_w = max(
            110,
            w
            - right_start
            - 22
        )

        y_top = (
            rect.top()
            + rect.height()
            * 0.22
        )

        y_mid = (
            rect.top()
            + rect.height()
            * 0.48
        )

        left_x = [
            24 + left_w * 0.18,
            24 + left_w * 0.42,
            24 + left_w * 0.66,
            24 + left_w * 0.88,
        ]

        right_x = [
            right_start
            + right_w
            * 0.12,

            right_start
            + right_w
            * 0.34,

            right_start
            + right_w
            * 0.58,

            right_start
            + right_w
            * 0.82,
        ]

        return [
            (
                left_x[0],
                y_top,
                0.82,
                1,
                "violin"
            ),

            (
                left_x[1],
                y_top + 2,
                0.80,
                1,
                "flute"
            ),

            (
                left_x[2],
                y_top - 1,
                0.84,
                1,
                "trumpet"
            ),

            (
                left_x[0],
                y_mid + 6,
                0.92,
                1,
                "cello"
            ),

            (
                left_x[1],
                y_mid,
                0.90,
                1,
                "violin"
            ),

            (
                left_x[2],
                y_mid + 4,
                0.92,
                1,
                "flute"
            ),

            (
                left_x[3],
                y_mid + 2,
                0.90,
                1,
                "violin"
            ),

            (
                right_x[0],
                y_top + 2,
                0.84,
                -1,
                "violin"
            ),

            (
                right_x[1],
                y_top - 2,
                0.82,
                -1,
                "trumpet"
            ),

            (
                right_x[2],
                y_top + 1,
                0.80,
                -1,
                "flute"
            ),

            (
                right_x[0],
                y_mid + 2,
                0.90,
                -1,
                "cello"
            ),

            (
                right_x[1],
                y_mid + 4,
                0.90,
                -1,
                "violin"
            ),

            (
                right_x[2],
                y_mid,
                0.92,
                -1,
                "flute"
            ),

            (
                right_x[3],
                y_mid + 6,
                0.90,
                -1,
                "violin"
            ),
        ]

    def draw_orchestra_pits(
        self,
        painter,
        w,
        rect
    ):
        painter.save()

        boxes = [
            QRectF(
                25,
                rect.top()
                + rect.height()
                * 0.25,
                rect.left()
                - 50,
                rect.height()
                * 0.68
            ),

            QRectF(
                rect.right()
                + 25,
                rect.top()
                + rect.height()
                * 0.25,
                w
                - rect.right()
                - 50,
                rect.height()
                * 0.68
            ),
        ]

        for box in boxes:
            if box.width() < 60:
                continue

            gradient = QLinearGradient(
                0,
                box.top(),
                0,
                box.bottom()
            )

            gradient.setColorAt(
                0.0,
                QColor(
                    53,
                    37,
                    29,
                    165
                )
            )

            gradient.setColorAt(
                1.0,
                QColor(
                    17,
                    13,
                    15,
                    225
                )
            )

            painter.setBrush(
                QBrush(gradient)
            )

            painter.setPen(
                QPen(
                    QColor(
                        184,
                        132,
                        64,
                        100
                    ),
                    2
                )
            )

            painter.drawRoundedRect(
                box,
                18,
                18
            )

        painter.restore()

    def draw_orchestra(
        self,
        painter,
        w,
        rect
    ):
        members = (
            self.get_orchestra_members(
                w,
                rect
            )
        )

        count = min(
            len(members),
            len(
                self.orchestra_instrument_progress
            )
        )

        for index in range(count):
            (
                x,
                y,
                scale,
                facing,
                instrument
            ) = members[index]

            self.draw_orchestra_member(
                painter,
                x,
                y,
                scale,
                facing,
                instrument,
                self.orchestra_instrument_progress[
                    index
                ]
            )

    def draw_orchestra_member(
        self,
        painter,
        x,
        y,
        scale,
        facing,
        instrument,
        progress
    ):
        painter.save()

        skin = QColor(
            218,
            181,
            143
        )

        tux = QColor(
            34,
            37,
            45
        )

        shirt = QColor(
            242,
            239,
            230
        )

        painter.setBrush(
            QColor(
                92,
                24,
                36
            )
        )

        painter.setPen(
            QPen(
                QColor(
                    135,
                    89,
                    48
                ),
                1
            )
        )

        painter.drawRoundedRect(
            QRectF(
                x - 13 * scale,
                y + 21 * scale,
                26 * scale,
                27 * scale
            ),
            5,
            5
        )

        painter.setPen(Qt.NoPen)

        painter.setBrush(
            QColor(
                0,
                0,
                0,
                90
            )
        )

        painter.drawEllipse(
            QRectF(
                x - 18 * scale,
                y + 54 * scale,
                36 * scale,
                8 * scale
            )
        )

        painter.setBrush(skin)

        painter.drawEllipse(
            QRectF(
                x - 9 * scale,
                y - 9 * scale,
                18 * scale,
                18 * scale
            )
        )

        painter.setBrush(tux)

        painter.setPen(
            QPen(
                QColor(
                    135,
                    112,
                    84,
                    130
                ),
                1
            )
        )

        painter.drawRoundedRect(
            QRectF(
                x - 11 * scale,
                y + 8 * scale,
                22 * scale,
                33 * scale
            ),
            4,
            4
        )

        painter.setPen(Qt.NoPen)
        painter.setBrush(shirt)

        painter.drawRect(
            QRectF(
                x - 3 * scale,
                y + 11 * scale,
                6 * scale,
                18 * scale
            )
        )

        if instrument == "cello":
            hold_x = (
                x
                + facing
                * 14
                * scale
            )

            hold_y = (
                y
                + 26
                * scale
            )

            drop_x = (
                x
                + facing
                * 30
                * scale
            )

            drop_y = (
                y
                + 66
                * scale
            )

        elif instrument == "flute":
            hold_x = (
                x
                + facing
                * 13
                * scale
            )

            hold_y = (
                y
                + 16
                * scale
            )

            drop_x = (
                x
                + facing
                * 34
                * scale
            )

            drop_y = (
                y
                + 59
                * scale
            )

        elif instrument == "trumpet":
            hold_x = (
                x
                + facing
                * 14
                * scale
            )

            hold_y = (
                y
                + 16
                * scale
            )

            drop_x = (
                x
                + facing
                * 35
                * scale
            )

            drop_y = (
                y
                + 61
                * scale
            )

        else:
            hold_x = (
                x
                + facing
                * 12
                * scale
            )

            hold_y = (
                y
                + 18
                * scale
            )

            drop_x = (
                x
                + facing
                * 32
                * scale
            )

            drop_y = (
                y
                + 62
                * scale
            )

        ix = (
            drop_x
            + (
                hold_x
                - drop_x
            )
            * progress
        )

        iy = (
            drop_y
            + (
                hold_y
                - drop_y
            )
            * progress
        )

        if progress < 0.50:
            painter.setPen(Qt.NoPen)

            painter.setBrush(
                QColor(
                    230,
                    182,
                    85,
                    48
                )
            )

            painter.drawEllipse(
                QRectF(
                    drop_x
                    - 19
                    * scale,

                    drop_y
                    - 8
                    * scale,

                    38
                    * scale,

                    16
                    * scale
                )
            )

        arm = QPen(
            skin,
            max(
                2,
                int(
                    3 * scale
                )
            )
        )

        arm.setCapStyle(
            Qt.RoundCap
        )

        painter.setPen(arm)

        if progress > 0.2:
            painter.drawLine(
                QPointF(
                    x - 6 * scale,
                    y + 18 * scale
                ),
                QPointF(
                    ix
                    - facing
                    * 5
                    * scale,
                    iy
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6 * scale,
                    y + 18 * scale
                ),
                QPointF(
                    ix
                    + facing
                    * 5
                    * scale,
                    iy + 3
                )
            )

        else:
            painter.drawLine(
                QPointF(
                    x - 6 * scale,
                    y + 18 * scale
                ),
                QPointF(
                    x - 8 * scale,
                    y + 40 * scale
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6 * scale,
                    y + 18 * scale
                ),
                QPointF(
                    x + 8 * scale,
                    y + 40 * scale
                )
            )

        self.draw_instrument(
            painter,
            ix,
            iy,
            scale,
            facing,
            instrument,
            progress
        )

        painter.restore()

    def draw_instrument(
        self,
        painter,
        x,
        y,
        scale,
        facing,
        instrument,
        progress
    ):
        painter.save()

        painter.translate(
            x,
            y
        )

        painter.rotate(
            facing
            * (
                1.0
                - progress
            )
            * 85
        )

        if instrument == "violin":
            painter.setBrush(
                QColor("#B56C33")
            )

            painter.setPen(
                QPen(
                    QColor("#6A3B1E"),
                    1
                )
            )

            painter.drawEllipse(
                QRectF(
                    -8 * scale,
                    -6 * scale,
                    16 * scale,
                    12 * scale
                )
            )

            painter.drawLine(
                QPointF(
                    5 * facing * scale,
                    0
                ),
                QPointF(
                    18 * facing * scale,
                    0
                )
            )

        elif instrument == "cello":
            painter.setBrush(
                QColor("#A25A2A")
            )

            painter.setPen(
                QPen(
                    QColor("#613118"),
                    1
                )
            )

            painter.drawEllipse(
                QRectF(
                    -8 * scale,
                    -15 * scale,
                    16 * scale,
                    30 * scale
                )
            )

            painter.drawLine(
                QPointF(
                    0,
                    -14 * scale
                ),
                QPointF(
                    0,
                    -30 * scale
                )
            )

        elif instrument == "flute":
            painter.setPen(
                QPen(
                    QColor("#E3E7EC"),
                    3
                )
            )

            painter.drawLine(
                QPointF(
                    -18 * facing * scale,
                    0
                ),
                QPointF(
                    18 * facing * scale,
                    0
                )
            )

        else:
            painter.setPen(
                QPen(
                    QColor("#E1B248"),
                    3
                )
            )

            painter.drawLine(
                QPointF(
                    -8 * facing * scale,
                    0
                ),
                QPointF(
                    20 * facing * scale,
                    0
                )
            )

        painter.restore()

    # ==================================================
    # VIDEO DRAW
    # ==================================================

    def draw_video(
        self,
        painter,
        rect
    ):
        painter.save()

        painter.setPen(Qt.NoPen)

        painter.setBrush(
            QColor(
                0,
                0,
                0,
                150
            )
        )

        painter.drawRoundedRect(
            rect.adjusted(
                -12,
                -12,
                12,
                12
            ),
            16,
            16
        )

        frame = QLinearGradient(
            rect.left(),
            rect.top(),
            rect.right(),
            rect.bottom()
        )

        frame.setColorAt(
            0.0,
            QColor("#805B29")
        )

        frame.setColorAt(
            0.5,
            QColor("#E2BC68")
        )

        frame.setColorAt(
            1.0,
            QColor("#67451E")
        )

        painter.setBrush(
            QBrush(frame)
        )

        painter.drawRoundedRect(
            rect,
            11,
            11
        )

        content = rect.adjusted(
            9,
            9,
            -9,
            -9
        )

        painter.fillRect(
            content,
            QColor("#020305")
        )

        if (
            self.video_frame
            is not None
            and
            not self.video_frame.isNull()
        ):
            painter.drawImage(
                content,
                self.video_frame
            )

        else:
            painter.setPen(
                QColor(
                    175,
                    180,
                    190,
                    95
                )
            )

            painter.drawText(
                content,
                Qt.AlignCenter,
                "FPGA VGA\nCAPTURE INPUT"
            )

        if self.scene in (
            "READY",
            "PLAYING"
        ):
            self.draw_grid(
                painter,
                content
            )

            self.draw_beat_guide(
                painter,
                content
            )

            self.draw_zones(
                painter,
                content
            )

            self.draw_tracking(
                painter,
                content
            )

        badge_text = (
            "CAPTURE ON"
            if self.capture_active
            else "CAPTURE OFF"
        )

        badge_rect = QRectF(
            content.left() + 10,
            content.top() + 9,
            104,
            23
        )

        painter.setPen(
            QPen(
                QColor("#4FCB8B")
                if self.capture_active
                else QColor("#74777D"),
                1
            )
        )

        painter.setBrush(
            QColor(
                4,
                8,
                10,
                185
            )
        )

        painter.drawRoundedRect(
            badge_rect,
            5,
            5
        )

        badge_font = QFont(
            "Segoe UI"
        )
        badge_font.setPointSize(8)
        badge_font.setBold(True)

        painter.setFont(
            badge_font
        )

        painter.setPen(
            QColor("#68D99D")
            if self.capture_active
            else QColor("#989AA0")
        )

        painter.drawText(
            badge_rect,
            Qt.AlignCenter,
            badge_text
        )

        painter.restore()

    def draw_grid(
        self,
        painter,
        rect
    ):
        painter.save()

        painter.setPen(
            QPen(
                QColor(
                    236,
                    147,
                    57,
                    105
                ),
                1
            )
        )

        for i in (
            1,
            2
        ):
            x = (
                rect.left()
                + rect.width()
                * i / 3
            )

            y = (
                rect.top()
                + rect.height()
                * i / 3
            )

            painter.drawLine(
                QPointF(
                    x,
                    rect.top()
                ),
                QPointF(
                    x,
                    rect.bottom()
                )
            )

            painter.drawLine(
                QPointF(
                    rect.left(),
                    y
                ),
                QPointF(
                    rect.right(),
                    y
                )
            )

        painter.restore()

    # ==================================================
    # 4/4 GUIDE
    # ==================================================

    def draw_beat_guide(
        self,
        painter,
        rect
    ):
        painter.save()

        centers = {}

        for number, zone in (
            self.get_zone_items(
                rect
            )
        ):
            centers[number] = (
                zone.center()
            )

        path = QPainterPath()

        p1 = centers[1]
        p2 = centers[2]
        p3 = centers[3]
        p4 = centers[4]

        path.moveTo(
            p1
        )

        path.cubicTo(
            QPointF(
                p1.x(),
                (p1.y() + p2.y()) / 2
            ),
            QPointF(
                p2.x(),
                (p1.y() + p2.y()) / 2
            ),
            p2
        )

        path.cubicTo(
            QPointF(
                (p2.x() + p3.x()) / 2,
                p2.y()
            ),
            QPointF(
                (p2.x() + p3.x()) / 2,
                p3.y()
            ),
            p3
        )

        path.cubicTo(
            QPointF(
                p3.x(),
                (p3.y() + p4.y()) / 2
            ),
            QPointF(
                p4.x(),
                (p3.y() + p4.y()) / 2
            ),
            p4
        )

        path.cubicTo(
            QPointF(
                p4.x() + (p1.x() - p4.x()) * 0.35,
                p4.y() - abs(p1.y() - p4.y()) * 0.18
            ),
            QPointF(
                p1.x() - (p1.x() - p4.x()) * 0.35,
                p1.y() - abs(p1.y() - p4.y()) * 0.18
            ),
            p1
        )

        guide_pen = QPen(
            QColor(
                238,
                189,
                79,
                160
            ),
            2
        )

        guide_pen.setStyle(
            Qt.SolidLine
        )

        guide_pen.setCapStyle(
            Qt.RoundCap
        )

        guide_pen.setJoinStyle(
            Qt.RoundJoin
        )

        painter.setPen(
            guide_pen
        )

        painter.setBrush(
            Qt.NoBrush
        )

        painter.drawPath(
            path
        )

        font = QFont(
            "Segoe UI"
        )

        font.setPointSize(9)
        font.setBold(True)

        painter.setFont(font)

        painter.setPen(
            QColor(
                229,
                186,
                94,
                120
            )
        )

        painter.drawText(
            QRectF(
                rect.left() + 8,
                rect.top() + 7,
                110,
                20
            ),
            Qt.AlignLeft,
            "4/4 GUIDE"
        )

        painter.restore()

    # ==================================================
    # ZONES
    # ==================================================

    def draw_zones(
        self,
        painter,
        rect
    ):
        painter.save()

        note_font = QFont(
            "Segoe UI Symbol"
        )

        note_font.setPointSize(13)
        note_font.setBold(True)

        num_font = QFont(
            "Segoe UI"
        )

        num_font.setPointSize(13)
        num_font.setBold(True)

        for number, zone in (
            self.get_zone_items(
                rect
            )
        ):
            active = False

            if (
                self.pattern
                == PATTERN_READY
                and
                number == 4
            ):
                active = True

            elif (
                self.pattern
                == number + 2
            ):
                active = True

            if active:
                fill = QColor(
                    255,
                    196,
                    58,
                    120
                )

                border = QColor(
                    255,
                    230,
                    125,
                    245
                )

            else:
                fill = QColor(
                    230,
                    135,
                    45,
                    22
                )

                border = QColor(
                    235,
                    155,
                    70,
                    125
                )

            painter.setBrush(
                fill
            )

            painter.setPen(
                QPen(
                    border,
                    2
                    if active
                    else 1
                )
            )

            painter.drawRoundedRect(
                zone,
                5,
                5
            )

            painter.setFont(
                note_font
            )

            painter.setPen(
                QColor(
                    255,
                    237,
                    195,
                    250
                    if active
                    else 135
                )
            )

            painter.drawText(
                QRectF(
                    zone.left(),
                    zone.top(),
                    zone.width(),
                    zone.height()
                    * 0.50
                ),
                Qt.AlignCenter,
                "♪"
            )

            painter.setFont(
                num_font
            )

            painter.drawText(
                QRectF(
                    zone.left(),
                    zone.top()
                    + zone.height()
                    * 0.42,
                    zone.width(),
                    zone.height()
                    * 0.48
                ),
                Qt.AlignCenter,
                str(number)
            )

        painter.restore()

    def draw_tracking(
        self,
        painter,
        rect
    ):
        if not getattr(self, "capture_active", False):
            self.draw_virtual_stick(
                painter,
                rect,
                self.red_x,
                self.red_y
            )

            self.draw_virtual_hand(
                painter,
                rect,
                self.green_x,
                self.green_y
            )

            return

        painter.save()

        for x_value, y_value, color in (
            (
                self.red_x,
                self.red_y,
                QColor("#FF453A")
            ),
            (
                self.green_x,
                self.green_y,
                QColor("#44DF79")
            ),
        ):
            if (
                x_value == 1023
                or
                y_value == 1023
            ):
                continue

            if not (
                0 <= x_value < 320
                and
                0 <= y_value < 240
            ):
                continue

            x, y = self.source_to_screen(
                rect,
                x_value,
                y_value
            )

            painter.setPen(Qt.NoPen)
            painter.setBrush(color)

            painter.drawEllipse(
                QRectF(
                    x - 5,
                    y - 5,
                    10,
                    10
                )
            )

        painter.restore()

    def virtual_object_scale(
        self,
        rect
    ):
        sx = rect.width() / 600.0
        sy = rect.height() / 450.0

        return max(
            0.72,
            min(
                1.20,
                min(sx, sy)
            )
        )



    def draw_virtual_stick(
        self,
        painter,
        rect,
        x_value,
        y_value
    ):
        if (
            x_value == 1023
            or
            y_value == 1023
        ):
            return

        if not (
            0 <= x_value < 320
            and
            0 <= y_value < 240
        ):
            return

        x, y = self.source_to_screen(
            rect,
            x_value,
            y_value
        )

        scale = self.virtual_object_scale(rect)

        # 빨간 구슬 기준 크기
        orb_r = 10.5 * scale

        # 지팡이 전체 길이 / 두께
        shaft_len = 92 * scale
        shaft_top_w = 7.5 * scale
        shaft_mid_w = 5.5 * scale
        shaft_bot_w = 3.2 * scale

        painter.save()
        painter.setRenderHint(
            QPainter.Antialiasing,
            True
        )
        painter.setClipRect(rect)

        # ==================================================
        # 1) 지팡이 몸통 (살짝 울퉁불퉁한 테이퍼 형태)
        # ==================================================

        top_y = y + orb_r * 0.75
        bottom_y = top_y + shaft_len

        shaft = QPainterPath()
        shaft.moveTo(x - shaft_top_w / 2, top_y)

        shaft.cubicTo(
            x - 8.0 * scale, y + 30 * scale,
            x - 5.0 * scale, y + 55 * scale,
            x - shaft_mid_w / 2, y + 64 * scale
        )

        shaft.cubicTo(
            x - 6.0 * scale, y + 80 * scale,
            x - 4.0 * scale, y + 100 * scale,
            x - shaft_bot_w / 2, bottom_y - 10 * scale
        )

        shaft.lineTo(x, bottom_y)

        shaft.lineTo(x + shaft_bot_w / 2, bottom_y - 10 * scale)

        shaft.cubicTo(
            x + 4.0 * scale, y + 100 * scale,
            x + 6.0 * scale, y + 80 * scale,
            x + shaft_mid_w / 2, y + 64 * scale
        )

        shaft.cubicTo(
            x + 5.0 * scale, y + 55 * scale,
            x + 8.0 * scale, y + 30 * scale,
            x + shaft_top_w / 2, top_y
        )

        shaft.closeSubpath()

        painter.setPen(
            QPen(
                QColor(70, 44, 27, 180),
                max(1.0, 1.0 * scale)
            )
        )
        painter.setBrush(
            QColor("#5F3D28")
        )
        painter.drawPath(shaft)

        # ==================================================
        # 2) 몸통 하이라이트
        # ==================================================
        highlight = QPainterPath()
        highlight.moveTo(
            x - 1.7 * scale,
            top_y + 4 * scale
        )
        highlight.cubicTo(
            x - 4.2 * scale, y + 34 * scale,
            x - 2.8 * scale, y + 61 * scale,
            x - 1.0 * scale, y + 89 * scale
        )
        highlight.cubicTo(
            x - 0.6 * scale, y + 98 * scale,
            x - 1.2 * scale, y + 108 * scale,
            x - 0.4 * scale, bottom_y - 10 * scale
        )

        painter.setPen(
            QPen(
                QColor(170, 120, 82, 120),
                max(1.0, 1.2 * scale)
            )
        )
        painter.setBrush(Qt.NoBrush)
        painter.drawPath(highlight)

        # ==================================================
        # 3) 울퉁불퉁한 마디 느낌
        # ==================================================
        knot_color = QColor("#4C2F1F")
        painter.setPen(Qt.NoPen)
        painter.setBrush(knot_color)

        knot_specs = (
            (y + 24 * scale, 8.0 * scale, 4.2 * scale),
            (y + 43 * scale, 6.8 * scale, 3.6 * scale),
            (y + 66 * scale, 6.0 * scale, 3.4 * scale),
            (y + 87 * scale, 5.2 * scale, 3.0 * scale),
        )

        for ky, kw, kh in knot_specs:
            painter.drawEllipse(
                QRectF(
                    x - kw / 2,
                    ky - kh / 2,
                    kw,
                    kh
                )
            )

        # ==================================================
        # 4) 빨간 구슬 아래 받침
        # ==================================================
        painter.setPen(
            QPen(
                QColor(80, 49, 31, 170),
                max(1.0, 1.0 * scale)
            )
        )
        painter.setBrush(
            QColor("#6B4730")
        )

        painter.drawRoundedRect(
            QRectF(
                x - 5.5 * scale,
                y + orb_r * 0.35,
                11.0 * scale,
                7.0 * scale
            ),
            2.5 * scale,
            2.5 * scale
        )

        # ==================================================
        # 5) 빨간 구슬
        # ==================================================
        painter.setPen(
            QPen(
                QColor(255, 150, 150, 180),
                max(1.0, 1.2 * scale)
            )
        )
        painter.setBrush(
            QColor("#E51E2A")
        )

        painter.drawEllipse(
            QRectF(
                x - orb_r,
                y - orb_r,
                orb_r * 2,
                orb_r * 2
            )
        )

        # 구슬 안쪽 그라데이션 느낌용 보조 하이라이트
        painter.setPen(Qt.NoPen)
        painter.setBrush(
            QColor(255, 255, 255, 70)
        )
        painter.drawEllipse(
            QRectF(
                x - orb_r * 0.45,
                y - orb_r * 0.58,
                orb_r * 0.62,
                orb_r * 0.50
            )
        )

        # 아주 약한 붉은 글로우
        painter.setBrush(
            QColor(255, 60, 60, 35)
        )
        painter.drawEllipse(
            QRectF(
                x - orb_r * 1.45,
                y - orb_r * 1.45,
                orb_r * 2.9,
                orb_r * 2.9
            )
        )

        painter.restore()



    def draw_virtual_hand(
        self,
        painter,
        rect,
        x_value,
        y_value
    ):
        if (
            x_value == 1023
            or
            y_value == 1023
        ):
            return

        if not (
            0 <= x_value < 320
            and
            0 <= y_value < 240
        ):
            return

        x, y = self.source_to_screen(
            rect,
            x_value,
            y_value
        )

        scale = self.virtual_object_scale(rect)
        green = QColor("#1FB44D")

        palm_w = 48 * scale
        palm_h = 28 * scale
        finger_width = 10 * scale

        painter.save()
        painter.setClipRect(rect)

        # Palm
        painter.setPen(Qt.NoPen)
        painter.setBrush(green)

        painter.drawRoundedRect(
            QRectF(
                x - palm_w / 2,
                y - palm_h / 2,
                palm_w,
                palm_h
            ),
            9 * scale,
            9 * scale
        )

        # Five fingers
        finger_pen = QPen(
            green,
            finger_width
        )
        finger_pen.setCapStyle(Qt.RoundCap)
        finger_pen.setJoinStyle(Qt.RoundJoin)
        painter.setPen(finger_pen)

        fingers = (
            ((-18, -1), (-34, -18)),
            ((-12, -8), (-20, -39)),
            ((-4, -10), (-4, -46)),
            ((6, -9), (13, -41)),
            ((15, -5), (30, -28)),
        )

        for (
            start_xy,
            end_xy
        ) in fingers:
            x1, y1 = start_xy
            x2, y2 = end_xy

            painter.drawLine(
                QPointF(
                    x + x1 * scale,
                    y + y1 * scale
                ),
                QPointF(
                    x + x2 * scale,
                    y + y2 * scale
                )
            )

        # Wrist
        painter.setPen(Qt.NoPen)
        painter.setBrush(green)

        painter.drawRoundedRect(
            QRectF(
                x - 13 * scale,
                y + 8 * scale,
                26 * scale,
                18 * scale
            ),
            6 * scale,
            6 * scale
        )

        painter.restore()

    # ==================================================
    # FLOOR
    # ==================================================

    def draw_floor(
        self,
        painter,
        w,
        h,
        rect
    ):
        gradient = QLinearGradient(
            0,
            rect.bottom(),
            0,
            h
        )

        gradient.setColorAt(
            0.0,
            QColor(
                70,
                44,
                27,
                80
            )
        )

        gradient.setColorAt(
            1.0,
            QColor(
                8,
                6,
                7,
                0
            )
        )

        painter.fillRect(
            QRectF(
                0,
                rect.bottom(),
                w,
                h
                - rect.bottom()
            ),
            QBrush(gradient)
        )

    # ==================================================
    # SEATED AUDIENCE
    # ==================================================

    def draw_seated_audience(
        self,
        painter,
        w,
        h,
        stage_bottom
    ):
        slots = (
            self.build_seated_slots(
                w,
                h,
                stage_bottom
            )
        )

        # 의자는 항상 전부 유지
        for slot in slots:
            self.draw_seat(
                painter,
                slot["x"],
                slot["y"],
                slot["scale"]
            )

        # 사람만 score에 따라 퇴장
        for index, slot in enumerate(
            slots
        ):
            if (
                index
                >= self.max_seated
            ):
                break

            presence = (
                self.seated_presence[index]
            )

            if presence <= 0.01:
                continue

            leave = (
                1.0
                - presence
            )

            direction = (
                -1
                if slot["t"] < 0
                else 1
            )

            x = (
                slot["x"]
                + direction
                * leave
                * 90
            )

            y = (
                slot["y"]
                + leave
                * 22
            )

            self.draw_person(
                painter,
                x,
                y,
                index,
                presence,
                slot["scale"],
                standing=False
            )

    # ==================================================
    # CURVED FENCE
    # ==================================================

    def draw_fan_fence(
        self,
        painter,
        w,
        h,
        stage_bottom
    ):
        if self.scene in (
            "MAIN",
            "MENU"
        ):
            return

        geometry = (
            self.get_fence_geometry(
                w,
                h,
                stage_bottom
            )
        )

        center_x = (
            geometry["center_x"]
        )

        center_y = (
            geometry["center_y"]
        )

        radius_x = (
            geometry["radius_x"]
        )

        edge_lift = (
            geometry["edge_lift"]
        )

        painter.save()

        samples = 60

        # 하단 레일
        lower_path = QPainterPath()

        for i in range(
            samples + 1
        ):
            t = (
                -1.0
                + 2.0
                * i
                / samples
            )

            x, y = (
                self.fan_point(
                    center_x,
                    center_y,
                    radius_x,
                    edge_lift,
                    t
                )
            )

            y += 7

            if i == 0:
                lower_path.moveTo(
                    x,
                    y
                )
            else:
                lower_path.lineTo(
                    x,
                    y
                )

        painter.setPen(
            QPen(
                QColor(
                    99,
                    62,
                    35,
                    210
                ),
                5
            )
        )

        painter.setBrush(
            Qt.NoBrush
        )

        painter.drawPath(
            lower_path
        )

        # 상단 금색 레일
        upper_path = QPainterPath()

        for i in range(
            samples + 1
        ):
            t = (
                -1.0
                + 2.0
                * i
                / samples
            )

            x, y = (
                self.fan_point(
                    center_x,
                    center_y,
                    radius_x,
                    edge_lift,
                    t
                )
            )

            if i == 0:
                upper_path.moveTo(
                    x,
                    y
                )
            else:
                upper_path.lineTo(
                    x,
                    y
                )

        painter.setPen(
            QPen(
                QColor(
                    190,
                    132,
                    58,
                    190
                ),
                3
            )
        )

        painter.drawPath(
            upper_path
        )

        # 세로 기둥
        post_values = [
            -1.0,
            -0.75,
            -0.50,
            -0.25,
            0.0,
            0.25,
            0.50,
            0.75,
            1.0,
        ]

        for t in post_values:
            x, y = (
                self.fan_point(
                    center_x,
                    center_y,
                    radius_x,
                    edge_lift,
                    t
                )
            )

            painter.setPen(
                QPen(
                    QColor(
                        169,
                        112,
                        54,
                        210
                    ),
                    3
                )
            )

            painter.drawLine(
                QPointF(
                    x,
                    y - 7
                ),
                QPointF(
                    x,
                    y + 20
                )
            )

            painter.setPen(
                Qt.NoPen
            )

            painter.setBrush(
                QColor(
                    221,
                    166,
                    77,
                    230
                )
            )

            painter.drawEllipse(
                QRectF(
                    x - 3,
                    y - 11,
                    6,
                    6
                )
            )

        painter.restore()

    # ==================================================
    # STANDING AUDIENCE
    # ==================================================

    def draw_standing_audience(
        self,
        painter,
        w,
        h,
        stage_bottom
    ):
        if self.scene in (
            "MAIN",
            "MENU"
        ):
            return

        slots = (
            self.build_standing_slots(
                w,
                h,
                stage_bottom
            )
        )

        for index, slot in enumerate(
            slots
        ):
            if (
                index
                >= self.max_standing
            ):
                break

            presence = (
                self.standing_presence[index]
            )

            if presence <= 0.01:
                continue

            leave = (
                1.0
                - presence
            )

            direction = (
                -1
                if slot["t"] < 0
                else 1
            )

            x = (
                slot["x"]
                + direction
                * leave
                * 95
            )

            y = (
                slot["y"]
                + leave
                * 15
            )

            self.draw_person(
                painter,
                x,
                y,
                index + 100,
                presence,
                slot["scale"],
                standing=True
            )

    # ==================================================
    # SEAT
    # ==================================================

    def draw_seat(
        self,
        painter,
        x,
        y,
        scale
    ):
        painter.save()

        painter.setBrush(
            QColor(
                78,
                17,
                28,
                245
            )
        )

        painter.setPen(
            QPen(
                QColor(
                    151,
                    99,
                    50,
                    185
                ),
                1
            )
        )

        painter.drawRoundedRect(
            QRectF(
                x
                - 11
                * scale,

                y + 5,

                22
                * scale,

                28
                * scale
            ),
            5,
            5
        )

        # 좌판
        painter.setBrush(
            QColor(
                106,
                25,
                37,
                245
            )
        )

        painter.drawRoundedRect(
            QRectF(
                x
                - 12
                * scale,

                y
                + 25
                * scale,

                24
                * scale,

                9
                * scale
            ),
            3,
            3
        )

        # 장식
        painter.setPen(
            QPen(
                QColor(
                    171,
                    115,
                    54,
                    200
                ),
                max(
                    1,
                    int(scale)
                )
            )
        )

        painter.drawLine(
            QPointF(
                x
                - 10
                * scale,

                y
                + 31
                * scale
            ),
            QPointF(
                x
                + 10
                * scale,

                y
                + 31
                * scale
            )
        )

        # 다리
        painter.setPen(
            QPen(
                QColor(
                    94,
                    69,
                    47,
                    180
                ),
                max(
                    1,
                    int(
                        2
                        * scale
                    )
                )
            )
        )

        painter.drawLine(
            QPointF(
                x
                - 7
                * scale,

                y
                + 32
                * scale
            ),
            QPointF(
                x
                - 7
                * scale,

                y
                + 38
                * scale
            )
        )

        painter.drawLine(
            QPointF(
                x
                + 7
                * scale,

                y
                + 32
                * scale
            ),
            QPointF(
                x
                + 7
                * scale,

                y
                + 38
                * scale
            )
        )

        painter.restore()

    # ==================================================
    # TOP HAT
    # ==================================================

    def has_tall_hat(
        self,
        index,
        standing
    ):
        seed = (
            index
            * 17
            + (
                11
                if standing
                else 5
            )
        ) % 29

        return seed in (
            2,
            11
        )

    def draw_tall_hat(
        self,
        painter,
        x,
        y,
        scale,
        alpha
    ):
        painter.save()

        brim_color = QColor(
            18,
            18,
            21,
            alpha
        )

        crown_dark = QColor(
            24,
            24,
            28,
            alpha
        )

        crown_light = QColor(
            48,
            48,
            55,
            alpha
        )

        band_color = QColor(
            8,
            8,
            10,
            alpha
        )

        gold = QColor(
            205,
            163,
            82,
            alpha
        )

        brim_w = (
            21
            * scale
        )

        brim_h = (
            5
            * scale
        )

        crown_w = (
            15
            * scale
        )

        crown_h = (
            19
            * scale
        )

        painter.setPen(
            QPen(
                QColor(
                    65,
                    65,
                    72,
                    alpha
                ),
                1
            )
        )

        painter.setBrush(
            brim_color
        )

        painter.drawEllipse(
            QRectF(
                x
                - brim_w
                / 2,

                y
                + scale,

                brim_w,

                brim_h
            )
        )

        gradient = QLinearGradient(
            x
            - crown_w
            / 2,

            y
            - crown_h,

            x
            + crown_w
            / 2,

            y
        )

        gradient.setColorAt(
            0.0,
            crown_light
        )

        gradient.setColorAt(
            0.5,
            crown_dark
        )

        gradient.setColorAt(
            1.0,
            crown_light
        )

        painter.setBrush(
            QBrush(gradient)
        )

        painter.drawRoundedRect(
            QRectF(
                x
                - crown_w
                / 2,

                y
                - crown_h,

                crown_w,

                crown_h
            ),
            3,
            3
        )

        painter.setPen(
            Qt.NoPen
        )

        painter.setBrush(
            band_color
        )

        painter.drawRect(
            QRectF(
                x
                - crown_w
                / 2,

                y
                - crown_h
                * 0.30,

                crown_w,

                4
                * scale
            )
        )

        painter.setBrush(
            gold
        )

        painter.drawRect(
            QRectF(
                x
                + crown_w
                * 0.18,

                y
                - crown_h
                * 0.28,

                3
                * scale,

                4
                * scale
            )
        )

        painter.restore()

    # ==================================================
    # PERSON
    # ==================================================

    def draw_person(
        self,
        painter,
        x,
        y,
        index,
        presence,
        scale,
        standing=False
    ):
        painter.save()

        alpha = int(
            presence
            * 255
        )

        head_r = (
            8.3
            * scale
        )

        body_w = (
            20
            * scale
        )

        body_h = (
            31
            * scale
            if standing
            else
            27
            * scale
        )

        skin_colors = [
            (
                205,
                168,
                132
            ),
            (
                220,
                179,
                140
            ),
            (
                181,
                143,
                112
            ),
            (
                195,
                157,
                125
            ),
        ]

        skin_rgb = (
            skin_colors[
                index
                % len(
                    skin_colors
                )
            ]
        )

        skin = QColor(
            skin_rgb[0],
            skin_rgb[1],
            skin_rgb[2],
            alpha
        )

        shirts = [
            (
                48,
                66,
                87
            ),
            (
                81,
                51,
                68
            ),
            (
                52,
                82,
                76
            ),
            (
                86,
                64,
                47
            ),
            (
                65,
                67,
                73
            ),
            (
                57,
                52,
                81
            ),
        ]

        shirt_rgb = (
            shirts[
                index
                % len(
                    shirts
                )
            ]
        )

        shirt = QColor(
            shirt_rgb[0],
            shirt_rgb[1],
            shirt_rgb[2],
            alpha
        )

        # shadow
        painter.setPen(
            Qt.NoPen
        )

        painter.setBrush(
            QColor(
                0,
                0,
                0,
                int(
                    70
                    * presence
                )
            )
        )

        painter.drawEllipse(
            QRectF(
                x
                - 15
                * scale,

                y
                + body_h,

                30
                * scale,

                7
                * scale
            )
        )

        # head
        painter.setBrush(
            skin
        )

        painter.drawEllipse(
            QRectF(
                x - head_r,
                y - head_r,
                head_r * 2,
                head_r * 2
            )
        )

        if self.has_tall_hat(
            index,
            standing
        ):
            self.draw_tall_hat(
                painter,
                x,
                y
                - head_r
                * 0.90,
                scale,
                alpha
            )

        # body
        painter.setBrush(
            shirt
        )

        painter.drawRoundedRect(
            QRectF(
                x
                - body_w
                / 2,

                y
                + head_r
                * 0.70,

                body_w,

                body_h
            ),
            5,
            5
        )

        arm = QPen(
            skin,
            max(
                2,
                int(
                    3
                    * scale
                )
            )
        )

        arm.setCapStyle(
            Qt.RoundCap
        )

        painter.setPen(
            arm
        )

        # READY 박수
        if self.scene == "READY":
            offset = (
                3
                if self.animation_phase
                else 0
            )

            painter.drawLine(
                QPointF(
                    x - 6,
                    y + 14
                ),
                QPointF(
                    x - 2 - offset,
                    y + 22
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6,
                    y + 14
                ),
                QPointF(
                    x + 2 + offset,
                    y + 22
                )
            )

        # LOW SCORE
        elif (
            self.scene == "PLAYING"
            and
            self.score <= 4
            and
            not standing
        ):
            painter.drawLine(
                QPointF(
                    x - 6,
                    y + 14
                ),
                QPointF(
                    x - head_r,
                    y
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6,
                    y + 14
                ),
                QPointF(
                    x + head_r,
                    y
                )
            )

        # HIGH SCORE
        elif (
            self.score >= 8
            or
            (
                standing
                and
                self.score >= 7
            )
        ):
            jump = (
                -3
                if self.animation_phase
                else 0
            )

            painter.drawLine(
                QPointF(
                    x - 6,
                    y + 14
                ),
                QPointF(
                    x - 15,
                    y - 13 + jump
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6,
                    y + 14
                ),
                QPointF(
                    x + 15,
                    y - 13 + jump
                )
            )

        else:
            painter.drawLine(
                QPointF(
                    x - 6,
                    y + 14
                ),
                QPointF(
                    x - 11,
                    y + 25
                )
            )

            painter.drawLine(
                QPointF(
                    x + 6,
                    y + 14
                ),
                QPointF(
                    x + 11,
                    y + 25
                )
            )

        if standing:
            painter.setPen(
                QPen(
                    QColor(
                        38,
                        38,
                        44,
                        alpha
                    ),
                    3
                )
            )

            painter.drawLine(
                QPointF(
                    x - 4,
                    y + body_h
                ),
                QPointF(
                    x - 6,
                    y + body_h + 14
                )
            )

            painter.drawLine(
                QPointF(
                    x + 4,
                    y + body_h
                ),
                QPointF(
                    x + 6,
                    y + body_h + 14
                )
            )

        painter.restore()

    # ==================================================
    # CURTAIN
    # ==================================================

    def draw_curtain(
        self,
        painter,
        rect
    ):
        if (
            self.curtain_progress
            <= 0.001
        ):
            return

        painter.save()

        width = (
            rect.width()
            * 0.5
            * self.curtain_progress
        )

        left = QRectF(
            rect.left(),
            rect.top(),
            width,
            rect.height()
        )

        right = QRectF(
            rect.right()
            - width,
            rect.top(),
            width,
            rect.height()
        )

        lg = QLinearGradient(
            left.left(),
            0,
            left.right(),
            0
        )

        lg.setColorAt(
            0.0,
            QColor("#26060D")
        )

        lg.setColorAt(
            0.45,
            QColor("#86172F")
        )

        lg.setColorAt(
            1.0,
            QColor("#350812")
        )

        rg = QLinearGradient(
            right.left(),
            0,
            right.right(),
            0
        )

        rg.setColorAt(
            0.0,
            QColor("#350812")
        )

        rg.setColorAt(
            0.55,
            QColor("#86172F")
        )

        rg.setColorAt(
            1.0,
            QColor("#26060D")
        )

        painter.fillRect(
            left,
            QBrush(lg)
        )

        painter.fillRect(
            right,
            QBrush(rg)
        )

        painter.restore()

    # ==================================================
    # SCENE TEXT
    # ==================================================

    def draw_scene_text(
        self,
        painter,
        rect
    ):
        painter.save()

        font = QFont(
            "Segoe UI"
        )

        font.setBold(True)

        if self.scene == "MAIN":
            font.setPointSize(26)

            painter.setFont(font)
            painter.setPen(
                QColor("#E8C77C")
            )

            painter.drawText(
                rect,
                Qt.AlignCenter,
                "MAESTRO"
            )

        elif self.scene == "MENU":
            font.setPointSize(18)

            painter.setFont(font)
            painter.setPen(
                QColor("#F2F2F2")
            )

            painter.drawText(
                rect,
                Qt.AlignCenter,
                "SELECT MUSIC"
            )

        elif self.scene == "READY":
            font.setPointSize(10)

            painter.setFont(font)

            painter.setPen(
                QColor(
                    233,
                    196,
                    105,
                    160
                )
            )

            if (
                self.pattern
                == PATTERN_READY
            ):
                text = (
                    "READY — MOVE THE BATON "
                    "FROM ZONE 4 TO ZONE 1"
                )

            elif (
                self.pattern
                == PATTERN_START
            ):
                text = (
                    "RAISE THE BATON TO ZONE 4"
                )

            else:
                text = (
                    "WAITING FOR CONDUCTOR"
                )

            # VGA 출력 화면 내부에 안내 문구를 표시.
            # 320x240 논리 좌표 기준으로 y=70~96 부근이라
            # Zone4(0~60)와 Zone2/3(110~160) 사이에 위치한다.
            painter.drawText(
                QRectF(
                    rect.left(),
                    rect.top() + rect.height() * (70 / 240),
                    rect.width(),
                    rect.height() * (26 / 240)
                ),
                Qt.AlignCenter,
                text
            )

        elif self.scene == "RESULT":
            font.setPointSize(25)

            painter.setFont(font)

            painter.setPen(
                QColor("#FAF5E8")
            )

            painter.drawText(
                rect,
                Qt.AlignCenter,
                f"FINAL SCORE\n"
                f"{self.final_score}"
            )

        painter.restore()


# =========================================================
# MAIN WINDOW
# =========================================================

class MainWindow(QMainWindow):

    title_start_requested = Signal()

    menu_requested = Signal()
    back_requested = Signal()

    start_requested = Signal(int)

    stop_requested = Signal()

    mock_zone4_ready_requested = Signal()
    mock_zone1_start_requested = Signal()

    mock_bpm_requested = Signal(int)
    mock_volume_requested = Signal(int)
    mock_score_requested = Signal(int)

    mock_song_end_requested = Signal()

    def __init__(self):
        super().__init__()

        self.setWindowTitle(
            "MAESTRO"
        )

        self.resize(
            1500,
            900
        )

        self.app_stack = (
            QStackedWidget()
        )

        self.title_screen = (
            TitleScreenWidget()
        )

        self.title_screen.start_requested.connect(
            self.title_start_requested.emit
        )

        self.game_page = QWidget()

        self.volume_bar = (
            VolumeBar()
        )

        self.stage = (
            StageWidget()
        )

        self.score_card = InfoCard(
            "SCORE",
            "50",
            "/ 100"
        )

        self.tempo_card = InfoCard(
            "TEMPO",
            "120",
            "BPM"
        )

        self.pattern_card = InfoCard(
            "PATTERN",
            "IDLE"
        )

        self.game_card = InfoCard(
            "GAME",
            "IDLE"
        )

        self.connection_label = QLabel(
            "● MOCK MODE"
        )

        self.connection_label.setObjectName(
            "connection"
        )

        self.debug_label = QLabel(
            "DEBUG"
        )

        self.debug_label.setObjectName(
            "debug"
        )

        self.control_stack = (
            QStackedWidget()
        )

        self.song_combo = (
            QComboBox()
        )


        self.song_combo.addItems(
            [
                "학교종",
                "나비야",
                "Mozart - Eine Kleine",
                "Ode to Joy",
                "Vivaldi - Spring",
            ]
        )

        self.build_game_page()

        self.app_stack.addWidget(
            self.title_screen
        )

        self.app_stack.addWidget(
            self.game_page
        )

        self.setCentralWidget(
            self.app_stack
        )

        self.apply_style()

        self.show_title_screen()

    # ==================================================
    # PAGE
    # ==================================================

    def show_title_screen(self):
        self.stage.stop_animation()

        self.app_stack.setCurrentWidget(
            self.title_screen
        )

    def show_game_screen(self):
        self.stage.start_animation()

        self.app_stack.setCurrentWidget(
            self.game_page
        )

    # ==================================================
    # GAME PAGE
    # ==================================================

    def build_game_page(self):
        root = QVBoxLayout()

        root.setContentsMargins(
            22,
            16,
            22,
            14
        )

        root.setSpacing(10)

        # HEADER
        header = QHBoxLayout()

        title_box = QVBoxLayout()

        title = QLabel(
            "MAESTRO"
        )

        title.setObjectName(
            "main_title"
        )

        subtitle = QLabel(
            "VGA CONDUCTOR SIMULATION"
        )

        subtitle.setObjectName(
            "subtitle"
        )

        title_box.addWidget(
            title
        )

        title_box.addWidget(
            subtitle
        )

        header.addLayout(
            title_box
        )

        header.addStretch()

        header.addWidget(
            self.connection_label
        )

        root.addLayout(
            header
        )

        # BODY
        body = QHBoxLayout()

        body.setSpacing(14)

        left = QFrame()

        left.setObjectName(
            "side_panel"
        )

        left_layout = (
            QVBoxLayout()
        )

        left_layout.addWidget(
            self.volume_bar
        )

        left.setLayout(
            left_layout
        )

        body.addWidget(
            left,
            1
        )

        body.addWidget(
            self.stage,
            8
        )

        right = QFrame()

        right.setObjectName(
            "side_panel"
        )

        right_layout = (
            QVBoxLayout()
        )

        right_layout.setSpacing(
            8
        )

        right_layout.addWidget(
            self.score_card
        )

        right_layout.addWidget(
            self.tempo_card
        )

        right_layout.addWidget(
            self.pattern_card
        )

        right_layout.addWidget(
            self.game_card
        )

        right_layout.addStretch()

        right.setLayout(
            right_layout
        )

        body.addWidget(
            right,
            2
        )

        root.addLayout(
            body,
            1
        )

        self.make_control_pages()

        root.addWidget(
            self.control_stack
        )

        root.addWidget(
            self.debug_controls
        )

        root.addWidget(
            self.debug_label
        )

        self.game_page.setLayout(
            root
        )

    # ==================================================
    # CONTROL PAGES
    # ==================================================

    def make_control_pages(self):
        # MAIN
        main_page = QFrame()

        main_page.setObjectName(
            "control_panel"
        )

        layout = QHBoxLayout()

        button = QPushButton(
            "MENU"
        )

        button.clicked.connect(
            self.menu_requested.emit
        )

        layout.addStretch()

        layout.addWidget(
            button
        )

        layout.addStretch()

        main_page.setLayout(
            layout
        )

        self.control_stack.addWidget(
            main_page
        )

        # MENU
        menu_page = QFrame()

        menu_page.setObjectName(
            "control_panel"
        )

        layout = QHBoxLayout()

        back = QPushButton(
            "BACK"
        )

        start = QPushButton(
            "START"
        )

        back.clicked.connect(
            self.back_requested.emit
        )

        start.clicked.connect(
            lambda:
            self.start_requested.emit(
                self.song_combo.currentIndex()
            )
        )

        layout.addWidget(
            back
        )

        layout.addStretch()

        layout.addWidget(
            QLabel(
                "MUSIC"
            )
        )

        layout.addWidget(
            self.song_combo
        )

        layout.addStretch()

        layout.addWidget(
            start
        )

        menu_page.setLayout(
            layout
        )

        self.control_stack.addWidget(
            menu_page
        )

        # GAME
        game_page = QFrame()

        game_page.setObjectName(
            "control_panel"
        )

        layout = QHBoxLayout()

        label = QLabel(
            "CONDUCTING SESSION"
        )

        label.setObjectName(
            "control_label"
        )

        stop = QPushButton(
            "STOP"
        )

        stop.clicked.connect(
            self.stop_requested.emit
        )

        layout.addWidget(
            label
        )

        layout.addStretch()

        layout.addWidget(
            stop
        )

        game_page.setLayout(
            layout
        )

        self.control_stack.addWidget(
            game_page
        )

        # RESULT
        result_page = QFrame()

        result_page.setObjectName(
            "control_panel"
        )

        layout = QHBoxLayout()

        label = QLabel(
            "PERFORMANCE RESULT"
        )

        label.setObjectName(
            "control_label"
        )

        label.setAlignment(
            Qt.AlignCenter
        )

        layout.addWidget(
            label
        )

        result_page.setLayout(
            layout
        )

        self.control_stack.addWidget(
            result_page
        )

        self.debug_controls = (
            self.make_debug_controls()
        )

    # ==================================================
    # DEBUG / MOCK
    # ==================================================

    def make_debug_controls(self):
        frame = QFrame()

        frame.setObjectName(
            "debug_panel"
        )

        layout = QHBoxLayout()

        layout.setContentsMargins(
            10,
            4,
            10,
            4
        )

        zone4_button = QPushButton(
            "ZONE 4 READY"
        )

        zone4_button.setObjectName(
            "dev_ready_button"
        )

        zone4_button.clicked.connect(
            self.mock_zone4_ready_requested.emit
        )

        zone1_button = QPushButton(
            "ZONE 1 START"
        )

        zone1_button.setObjectName(
            "dev_start_button"
        )

        zone1_button.clicked.connect(
            self.mock_zone1_start_requested.emit
        )

        end = QPushButton(
            "END SONG"
        )

        end.clicked.connect(
            self.mock_song_end_requested.emit
        )

        self.test_bpm_slider = QSlider(
            Qt.Horizontal
        )

        self.test_bpm_slider.setRange(
            40,
            220
        )

        self.test_bpm_slider.setValue(
            120
        )

        self.test_bpm_slider.setMinimumWidth(
            100
        )

        self.test_bpm_label = QLabel(
            "120"
        )

        self.test_volume_slider = QSlider(
            Qt.Horizontal
        )

        self.test_volume_slider.setRange(
            0,
            100
        )

        self.test_volume_slider.setValue(
            50
        )

        self.test_volume_slider.setMinimumWidth(
            90
        )

        self.test_volume_label = QLabel(
            "50"
        )

        self.test_score_slider = QSlider(
            Qt.Horizontal
        )

        self.test_score_slider.setRange(
            0,
            10
        )

        self.test_score_slider.setValue(
            5
        )

        self.test_score_slider.setMinimumWidth(
            90
        )

        self.test_score_label = QLabel(
            "50"
        )

        self.test_bpm_slider.valueChanged.connect(
            self.on_test_bpm_changed
        )

        self.test_volume_slider.valueChanged.connect(
            self.on_test_volume_changed
        )

        self.test_score_slider.valueChanged.connect(
            self.on_test_score_changed
        )

        dev = QLabel(
            "DEV"
        )

        dev.setObjectName(
            "dev_label"
        )

        layout.addWidget(
            dev
        )

        layout.addWidget(
            zone4_button
        )

        layout.addWidget(
            zone1_button
        )

        layout.addWidget(
            QLabel(
                "BPM"
            )
        )

        layout.addWidget(
            self.test_bpm_slider
        )

        layout.addWidget(
            self.test_bpm_label
        )

        layout.addWidget(
            QLabel(
                "VOL"
            )
        )

        layout.addWidget(
            self.test_volume_slider
        )

        layout.addWidget(
            self.test_volume_label
        )

        layout.addWidget(
            QLabel(
                "SCORE"
            )
        )

        layout.addWidget(
            self.test_score_slider
        )

        layout.addWidget(
            self.test_score_label
        )

        layout.addWidget(
            end
        )

        frame.setLayout(
            layout
        )

        return frame

    def on_test_bpm_changed(
        self,
        value
    ):
        self.test_bpm_label.setText(
            str(value)
        )

        self.mock_bpm_requested.emit(
            value
        )

    def on_test_volume_changed(
        self,
        value
    ):
        self.test_volume_label.setText(
            str(value)
        )

        self.mock_volume_requested.emit(
            value
        )

    def on_test_score_changed(
        self,
        value
    ):
        self.test_score_label.setText(
            str(
                value
                * 10
            )
        )

        self.mock_score_requested.emit(
            value
        )

    # ==================================================
    # SCENE
    # ==================================================

    def set_scene(
        self,
        scene
    ):
        self.show_game_screen()

        self.stage.set_scene(
            scene
        )

        if scene == "MAIN":
            self.control_stack.setCurrentIndex(
                0
            )

        elif scene == "MENU":
            self.control_stack.setCurrentIndex(
                1
            )

        elif scene in (
            "READY",
            "PLAYING"
        ):
            self.control_stack.setCurrentIndex(
                2
            )

        elif scene == "RESULT":
            self.control_stack.setCurrentIndex(
                3
            )

    def set_result(
        self,
        score
    ):
        self.stage.set_final_score(
            score
        )

        self.set_scene(
            "RESULT"
        )

    # ==================================================
    # FPGA DATA
    # ==================================================

    def update_fpga_data(
        self,
        data
    ):
        self.volume_bar.set_volume(
            data["volume"]
        )

        score = (
            int(
                data["score"]
            )
            * 10
        )

        self.score_card.set_value(
            score
        )

        self.tempo_card.set_value(
            data["speed"]
        )

        pattern = int(
            data["pattern"]
        )

        short_pattern_names = {
            PATTERN_IDLE:
                "IDLE",

            PATTERN_START:
                "START",

            PATTERN_READY:
                "READY (Z4)",

            PATTERN_1:
                "P1 (Z1)",

            PATTERN_2:
                "P2 (Z2)",

            PATTERN_3:
                "P3 (Z3)",

            PATTERN_4:
                "P4 (Z4)",

            PATTERN_STOP:
                "STOP",
        }

        self.pattern_card.set_value(
            short_pattern_names.get(
                pattern,
                str(pattern)
            )
        )

        game_names = {
            0: "IDLE",
            1: "READY",
            2: "PLAYING",
        }

        self.game_card.set_value(
            game_names.get(
                data["game_fsm"],
                str(
                    data["game_fsm"]
                )
            )
        )

        self.stage.set_fpga_data(
            data
        )

        (
            seated,
            standing
        ) = self.stage.score_to_targets(
            data["score"]
        )

        capture_text = (
            "CAPTURE ON"
            if self.stage.capture_active
            else "CAPTURE OFF"
        )

        self.debug_label.setText(
            f"{capture_text}     "
            f"RED "
            f"({data['red_x']}, {data['red_y']})     "
            f"GREEN "
            f"({data['green_x']}, {data['green_y']})     "
            f"FSM {data['game_fsm']}     "
            f"PATTERN {pattern}:"
            f"{PATTERN_NAMES.get(pattern, 'UNKNOWN')}     "
            f"VOL {data['volume']}     "
            f"BPM {data['speed']}     "
            f"SCORE {score}     "
            f"SEATED {seated}     "
            f"STANDING {standing}"
        )

    # ==================================================
    # STYLE
    # ==================================================

    def apply_style(self):
        self.setStyleSheet("""
        QMainWindow {
            background-color: #060709;
        }

        QWidget {
            color: #E7E9EC;
            font-family: "Segoe UI";
            font-size: 13px;
        }

        #main_title {
            font-size: 27px;
            font-weight: 800;
            color: #E5C47C;
        }

        #subtitle {
            font-size: 10px;
            color: #666C76;
            letter-spacing: 2px;
        }

        #connection {
            color: #E0BD65;
            font-size: 11px;
            font-weight: 700;
            background-color: #111318;
            border: 1px solid #292D35;
            border-radius: 9px;
            padding: 8px 12px;
        }

        #side_panel {
            background-color: #0D0F13;
            border: 1px solid #29251F;
            border-radius: 12px;
        }

        #info_card {
            background-color: #15171C;
            border: 1px solid #322D26;
            border-radius: 9px;
            min-height: 92px;
        }

        #info_title {
            color: #858080;
            font-size: 10px;
            font-weight: 700;
        }

        #info_value {
            color: #F4F0E8;
            font-size: 24px;
            font-weight: 800;
        }

        #info_unit {
            color: #77736D;
            font-size: 10px;
        }

        #control_panel {
            background-color: #0D0F13;
            border: 1px solid #29251F;
            border-radius: 9px;
        }

        #control_label {
            color: #AAA49A;
            font-weight: 700;
        }

        #debug_panel {
            background-color: #090A0D;
            border: 1px solid #27231E;
            border-radius: 7px;
        }

        #dev_label {
            color: #B68A44;
            font-size: 10px;
            font-weight: 800;
        }

        QPushButton {
            min-width: 100px;
            color: #111216;
            background-color: #C99A47;
            border: none;
            border-radius: 7px;
            padding: 8px 12px;
            font-weight: 800;
        }

        QPushButton:hover {
            background-color: #DCAF59;
        }

        QPushButton:pressed {
            background-color: #A97B34;
        }

        #dev_ready_button {
            background-color: #D5A649;
        }

        #dev_ready_button:hover {
            background-color: #E5B85B;
        }

        #dev_start_button {
            background-color: #64B78B;
        }

        #dev_start_button:hover {
            background-color: #77CA9D;
        }

        QComboBox {
            min-width: 200px;
            color: #ECE8E0;
            background-color: #17181D;
            border: 1px solid #39332A;
            border-radius: 7px;
            padding: 8px 12px;
        }

        QSlider::groove:horizontal {
            height: 4px;
            background-color: #34302A;
            border-radius: 2px;
        }

        QSlider::handle:horizontal {
            width: 14px;
            height: 14px;
            margin: -5px 0;
            background-color: #D1A04B;
            border-radius: 7px;
        }

        #debug {
            color: #56524D;
            font-family: "Consolas";
            font-size: 9px;
        }
        """)