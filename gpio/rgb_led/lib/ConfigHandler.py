# -*- encoding: utf-8 -*-
#!/Library/Frameworks/Python.framework/Versions/3.6/bin/python3
import json
import time
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(myfolder)
import LogHandler
mylogger = LogHandler.LogHandler("confighandler")

try:
    sys.path.append( os.path.join(myfolder, "../../../tools/socketmem/lib/") )
    import clientMemDict
    socketdict = clientMemDict.SocketDictClient()
except Exception as e:
    socketdict = None
    print("Socket client error: " + str(e))

def cmp(a, b):
    diff = 0
    for key, value in a.items():
        if key not in b.keys():
            diff += 1
    if diff == 0:
        for key, value in a.items():
            if str(value) != str(b[key]):
                diff += 1
    return diff

class ConfigHandler():
    def __init__(self):
        self.stored_dict = {}

    # EXTERNAL FUNCTIONS - GET VALUE
    def get(self, key):
        if socketdict is not None:
            print("2.0 socket comm")
            value =  socketdict.get_parameter(namespace="rgb", key=key).decode()
        else:
            print("value error")
        return value

    # EXTERNAL FUNCTION - GET ALL
    def get_all(self):
        red = socketdict.get_parameter(namespace="rgb", key="RED").decode()
        green = socketdict.get_parameter(namespace="rgb", key="GREEN").decode()
        blue = socketdict.get_parameter(namespace="rgb", key="BLUE").decode()
        led = socketdict.get_parameter(namespace="rgb", key="LED").decode()
        service = socketdict.get_parameter(namespace="rgb", key="SERVICE").decode()
        config = { "RED": red,
                   "GREEN": green,
                   "BLUE": blue,
                   "LED": led,
                   "SERVICE": service
                 }
        self.stored_dict = config
        return config

    # EXTERNAL FUNCTION - PUT VALUE
    def put(self, key, value):
        if socketdict is not None:
            socketdict.set_parameter(namespace="rgb", key=key, value=value)

    # FILE IS MODIFIED CHECK
    def file_is_modified(self):
        is_modified = False
        red = socketdict.get_parameter(namespace="rgb", key="RED").decode()
        green = socketdict.get_parameter(namespace="rgb", key="GREEN").decode()
        blue = socketdict.get_parameter(namespace="rgb", key="BLUE").decode()
        led = socketdict.get_parameter(namespace="rgb", key="LED").decode()
        service = socketdict.get_parameter(namespace="rgb", key="SERVICE").decode()
        config = { "RED": red,
                   "GREEN": green,
                   "BLUE": blue,
                   "LED": led,
                   "SERVICE": service
                 }
        if 0 != cmp(config, self.stored_dict):
            is_modified = True
        return is_modified

    # CONFIG WATCHER: IF NO CHANGE RETURN NONE, IF CHANGES EXISTS RETURN FULL DICT
    def config_watcher(self, loop=False):
        try:
            all_param = None
            while loop:
                time.sleep(1)
                if self.file_is_modified():
                    all_param = self.get_all()
                    #print(all_param)
                    break

            if not loop:
                if self.file_is_modified():
                    all_param = self.get_all()
                    #print(all_param)
            return all_param
        except KeyboardInterrupt as e:
            raise Exception(e)
            mylogger.logger.info("Program is existing: Ctrl-C")

    def write_cfg_file(self, dictionary, retry=10, delay=0.1):
        pass

    def read_cfg_file(self, retry=10, delay=0.1):
        pass

class RGB_config_handler(ConfigHandler):
    def __init__(self):
        try:
            super().__init__()
        except:
            ConfigHandler.__init__(self)

    def put(self, color, duty_cycle, secure=True):
        if secure:
            if color == "RED" or color == "GREEN" or color == "BLUE":
                if duty_cycle < 100.0 or duty_cycle >= 0.0:
                    try:
                        super().put(color, duty_cycle)
                    except:
                        ConfigHandler.put(self, color, duty_cycle)
                else:
                    mylogger.logger.warning("Duty cycle not in range (0.0-100.0): " + str(duty_cycle))
            else:
                mylogger.logger.warning("Color is invalud: " + str(color))
        else:
            key = color
            value = duty_cycle
            try:
                super().put(key, value)
            except:
                ConfigHandler.put(self, key, value)

    def get(self, color, secure=True):
        if secure:
            if color == "RED" or color == "GREEN" or color == "BLUE":
                try:
                    dc = super().get(color)
                except:
                    dc = ConfigHandler.get(self, color)
            else:
                mylogger.logger.warning("Color is invalud: " + str(color))
                dc = None
            return dc
        else:
            key = color
            try:
                dc = super().get(key)
            except:
                dc = ConfigHandler.get(self, key)
            return dc

    def config_watcher(self):
        try:
            rgb_dict = super().config_watcher(loop=True)
        except:
            rgb_dict = ConfigHandler.config_watcher(self, loop=True)
        if int(rgb_dict["RED"]) > 100.0: rgb_dict["RED"] = 100.0
        if int(rgb_dict["RED"]) > 100.0: rgb_dict["RED"] = 100.0
        if int(rgb_dict["GREEN"]) > 100.0: rgb_dict["GREEN"] = 100.0
        if int(rgb_dict["GREEN"]) < 0.0: rgb_dict["GREEN"] = 0.0
        if int(rgb_dict["BLUE"]) < 0.0: rgb_dict["BLUE"] = 0.0
        if int(rgb_dict["BLUE"]) < 0.0: rgb_dict["BLUE"] = 0.0
        return rgb_dict

def test_ConfigHandler():
    config_path = str(myfolder) + "/rgb_config.json"
    cfg = ConfigHandler(config_path)

    # TEST: put, get
    print("TEST: put, get")
    print(cfg. get_all())
    cfg.put("test", "value")
    print(cfg. get_all())

    # TEST: cfg.file_is_modified() - return True or False
    print("TEST: cfg.file_is_modified() - return True or False")
    print(cfg.file_is_modified())                               # gets status, and set to to false
    print(cfg.file_is_modified())

    # RUN watcher
    print("RUN watcher")
    while True:
        try:
            rgb_dict = cfg.config_watcher(loop=True)
            print(rgb_dict)
        except KeyboardInterrupt as e:
            print("Program is existing: Ctrl-C")

if __name__ == "__main__":
    rgb = RGB_config_handler()

    # Put values
    print("Put values")
    rgb.put("RED", 50)
    rgb.put("GREEN", 40)
    rgb.put("BLUE", 30)

    # Get values
    print("TEST: Get values")
    print(rgb.get("RED"))
    print(rgb.get("GREEN"))
    print(rgb.get("BLUE"))

    # get all values
    print("TEST: get all values")
    print("TEST: get_all")

    # watch values
    print("TEST: watch values")
    while True:
        try:
            rgb_dict = rgb.config_watcher()
            print(rgb_dict)
        except KeyboardInterrupt as e:
            print("Program is existing: Ctrl-C")
