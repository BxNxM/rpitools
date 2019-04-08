import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(myfolder, "../../../../autodeployment/lib/")
sys.path.append(lib_path)
import ConfigHandler
SECTION = "HALARM"
CFG = None

def get_confighandler_object():
    global CFG
    if CFG is None:
        CFG = ConfigHandler.init(validate_print=False)
    return CFG

def get_HALARM_value_by_key(option):
    global SECTION
    cfg = get_confighandler_object()
    value = cfg.get(SECTION, option, reparse=False)
    return value

if __name__ == "__main__":
    print(get_HALARM_value_by_key("cpu_max_temp_alarm_celsius"))
