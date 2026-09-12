import serial
import serial.tools.list_ports


class SerialComm:

    def __init__(
        self,
        port=None,
        baudrate=115200
    ):

        self.port = port
        self.baudrate = baudrate
        self.ser = None

    @staticmethod
    def get_ports():

        ports = (
            serial.tools.list_ports.comports()
        )

        return [
            port.device
            for port in ports
        ]

    def is_connected(
        self
    ):

        return (
            self.ser is not None
            and
            self.ser.is_open
        )

    def connect(
        self
    ):

        if self.port is None:
            raise ValueError(
                "COM port가 지정되지 않았습니다."
            )

        if self.is_connected():
            return True

        self.ser = serial.Serial(
            port=self.port,
            baudrate=self.baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=0,
            write_timeout=0.2
        )

        # 연결 시 기존 PC serial buffer의
        # 오래된 byte를 비운 뒤 새 packet부터 받는다.
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()

        return True

    def disconnect(
        self
    ):

        if self.ser is not None:

            try:

                if self.ser.is_open:
                    self.ser.close()

            finally:

                self.ser = None

    # ==================================================
    # FPGA -> PC
    #
    # FPGA uart.sv:
    #
    # Byte0 = i_tx_data[7:0]
    # Byte1 = i_tx_data[15:8]
    # ...
    # Byte7 = i_tx_data[63:56]
    #
    # 따라서 PC에서는 little-endian으로
    # 64bit 원본을 복원한다.
    # ==================================================

    def receive_fpga_data(
        self
    ):

        if not self.is_connected():
            return None

        try:

            if self.ser.in_waiting < 8:
                return None

            raw = self.ser.read(
                8
            )

            if len(raw) != 8:
                return None

            return int.from_bytes(
                raw,
                byteorder="little",
                signed=False
            )

        except (
            serial.SerialException,
            OSError
        ) as e:

            print(
                "[UART RX ERROR] "
                f"{e}"
            )

            return None

    # ==================================================
    # PC -> FPGA
    #
    # 1 Byte:
    #
    # [7:4] GAME_STATE
    # [3:0] SONG_NUM
    # ==================================================

    def send_pc_data(
        self,
        value
    ):

        if not self.is_connected():
            return False

        try:

            packet = bytes(
                [
                    int(value)
                    & 0xFF
                ]
            )

            written = self.ser.write(
                packet
            )

            return (
                written == 1
            )

        except (
            serial.SerialException,
            OSError
        ) as e:

            print(
                "[UART TX ERROR] "
                f"{e}"
            )

            return False
