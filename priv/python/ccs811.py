"""
ccs811.py --- CCS811 reader
"""
from Adafruit_CCS811 import Adafruit_CCS811
from erlport.erlterms import Atom

MESSAGE_HANDLER_PID = None
CCS811_INSTANCE = None


def register(pid, _address):
    global MESSAGE_HANDLER_PID
    global CCS811_INSTANCE
    MESSAGE_HANDLER_PID = pid
    CCS811_INSTANCE = Adafruit_CCS811()
    return (Atom('ok'), pid)


def read():
    if MESSAGE_HANDLER_PID is None or CCS811_INSTANCE is None or not CCS811_INSTANCE.available():
        return (Atom('error'), (0, 0))

    if not CCS811_INSTANCE.readData():
        return (Atom('ok'), (CCS811_INSTANCE.geteCO2(), CCS811_INSTANCE.getTVOC()))
    else:
        return (Atom('error'), (0, 0))
