import datetime

def __init__RGB_schema():
    # inject_schema
    test_schema = {"rgb": { "BLUE": 55,
                            "GREEN": 55,
                            "LED": "OFF",
                            "RED": 65,
                            "SERVICE": "OFF",
                            "metadata": { "last_update": str(datetime.datetime.now())}
                          }
                  }
    return test_schema

def __init__oledBUTTONS_schema():
    # inject_schema
    test_schema = {"oled": { "sysbuttons": None,
                            "joystick": None,
                            "metadata": { "last_update": str(datetime.datetime.now())}
                          }
                  }
    return test_schema
