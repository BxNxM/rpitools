import datetime

def __init__RGB_schema():
    # inject_schema
    test_schema = {"rgb": { "BLUE": 55,
                            "GREEN": 55,
                            "LED": "OFF",
                            "RED": 65,
                            "SERVICE": "OFF",
                            "metadata": { "last_update": str(datetime.datetime.now()),
                                          "description": "RGB VALUES MULTIPROCESS COMMUNICATION, central store."}
                          }
                  }
    return test_schema

def __init__oledBUTTONS_schema():
    # inject_schema
    test_schema = {"oled": { "sysbuttons": None,
                            "joystick": None,
                            "metadata": { "last_update": str(datetime.datetime.now()),
                                        "description": "OLED BUTTONS MULTIPROCESS COMMUNICATION, central store."}
                          }
                  }
    return test_schema

def __init__generalFRAGMENT_schema():
    # inject_schema
    test_schema = {"general": { "service": "rpitools",
                                "born": "around2018",
                                "metadata": { "last_update": str(datetime.datetime.now()),
                                              "description": "GENERAL DEFAULT MEMDICT FRAGMENT for rpitools test purposes.",
                                              "dummykey": "dummyvalue" }
                          }
                  }
    return test_schema

def __init__systemHEALTH_schema():
    # inject_schema
    test_schema = {"system": { "linux_services": "unknown",
                               "rpitools_services": "unknown",
                               "processes": "unknown",
                               "disks": "unknown",
                               "temp": "unknown",
                               "cpu": "unknown",
                               "memory": "unknown",
                               "metadata": { "last_update": str(datetime.datetime.now()),
                                              "description": "SYSTEM HEALTH DATA collection for rpitools managed system.",
                                              "info": "" }
                          }
                  }
    return test_schema
