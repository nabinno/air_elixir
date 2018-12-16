"""
sds021.py --- SDS021 reader
"""
import time
import serial
from erlport.erlterms import Atom


class SDS021Result:
    """SDS021 sensor result returned by SDS021.read() method"""
    ERR_NO_ERROR = 0
    ERR_MISSING_DATA = 1
    ERR_CRC = 2
    error_code = ERR_NO_ERROR
    pm25 = -1
    pm10 = -1

    def __init__(self, error_code, pm25, pm10):
        self.error_code = error_code
        self.pm25 = pm25
        self.pm10 = pm10

    def is_valid(self):
        return self.error_code == SDS021Result.ERR_NO_ERROR


class SDS021:
    """SDS021 sensor reader class for Raspberry Pi"""
    SERIAL_INSTANCE = None

    def __init__(self, port):
        self.SERIAL_INSTANCE = serial.Serial(port, baudrate=9600)
        self.SERIAL_INSTANCE.setTimeout(1.5)

    def read(self):
        self.SERIAL_INSTANCE.flushInput()
        time.sleep(0.5)
        result = self.SERIAL_INSTANCE.read(10)
        if len(result) != 10:
            return SDS021Result(SDS021Result.ERR_MISSING_DATA, 0, 0)
        if result[0] != '\xaa' or result[1] != '\xc0':
            return SDS021Result(SDS021Result.ERR_CRC, 0, 0)
        checksum = 0
        for i in range(6):
            checksum = checksum + ord(result[2 + i])

        if checksum % 256 == ord(result[8]):
            pm25 = ord(result[2]) + ord(result[3]) * 256
            pm10 = ord(result[4]) + ord(result[5]) * 256
            return SDS021Result(SDS021Result.ERR_NO_ERROR, ('{:.1f}').format(pm25 / 10.0), ('{:.1f}').format(pm10 / 10.0))
        return SDS021Result(SDS021Result.ERR_CRC, 0, 0)

    def __show_hex(self, argv):
        result = ''
        hlen = len(argv)
        for i in range(hlen):
            hvol = argv[i]
            hhex = '%02x' % ord(hvol)
            result += hhex + ' '

        print ('ShowHex:', result)


MESSAGE_HANDLER_PID = None
SDS021_INSTANCE = None


def register(pid, port):
    global MESSAGE_HANDLER_PID
    global SDS021_INSTANCE
    MESSAGE_HANDLER_PID = pid
    SDS021_INSTANCE = SDS021(port)
    return (Atom('ok'), pid)


def read():
    if MESSAGE_HANDLER_PID is None or SDS021_INSTANCE is None:
        return (Atom('error'), (0, 0))

    result = SDS021_INSTANCE.read()
    if result.is_valid():
        return (Atom('ok'), (result.pm25, result.pm10))
    return (Atom('error'), (0, 0))
