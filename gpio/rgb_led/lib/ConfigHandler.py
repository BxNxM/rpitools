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

class ConfigHandler():
    def __init__(self, cfg_path):
        self.cfg_path = cfg_path
        self.file_last_modified_date = 0

    # EXTERNAL FUNCTIONS - GET VALUE
    def get(self, key):
        config = self.read_cfg_file()
        try:
            value = config[key]
        except:
            value = None
        return value

    # EXTERNAL FUNCTION - GET ALL
    def get_all(self):
        config = self.read_cfg_file()
        return config

    # EXTERNAL FUNCTION - PUT VALUE
    def put(self, key, value):
        config = self.read_cfg_file()
        config[key] = value
        self.write_cfg_file(config)

    # FILE IS MODIFIED CHECK
    def file_is_modified(self):
        moddate_raw = os.stat(self.cfg_path)[8]           # modification date
        moddate_hr = time.ctime(moddate_raw)            # human readable mod date
        is_modified = False
        if moddate_raw != self.file_last_modified_date:
            self.file_last_modified_date = moddate_raw
            is_modified = True
        return is_modified

    # CONFIG WATCHER: IF NO CHANGE RETURN NONE, IF CHANGES EXISTS RETURN FULL DICT
    def config_watcher(self, loop=False):
        try:
            all_param = None
            while loop:
                time.sleep(0.4)
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
        while retry > 0:
            try:
                with open(self.cfg_path, 'w') as f:
                    json.dump(dictionary, f, sort_keys=True, indent=2)
                    return True
            except Exception as e:
                mylogger.logger.info("ConfigHandler.write_cfg_file write json: " + str(e))
                retry -= 1
                time.sleep(delay)
        mylogger.logger.error("write_cfg_file")
        return False

    def read_cfg_file(self, retry=10, delay=0.1):
        while retry > 0:
            try:
                with open(self.cfg_path, 'r') as f:
                    data_dict = json.load(f)
                    return data_dict
            except Exception as e:
                mylogger.logger.info("ConfigHandler.read_cfg_file write json: " + str(e))
                retry -= 1
                time.sleep(delay)
        mylogger.logger.error("[ERROR] read_cfg_file")
        data_dict = {}
        return data_dict

class RGB_config_handler(ConfigHandler):
    def __init__(self, config_path):
        super().__init__(config_path)
        if not os.path.exists(config_path):
            # Create json filie
            mylogger.logger.info("set default config (config file not exists)")
            self.put("RED", 0)
            self.put("GREEN", 0)
            self.put("BLUE", 0)
            super().put("SERVICE", "ON")
            super().put("LED", "ON")

    def put(self, color, duty_cycle, secure=True):
        if secure:
            if color == "RED" or color == "GREEN" or color == "BLUE":
                if duty_cycle < 100.0 or duty_cycle >= 0.0:
                    super().put(color, duty_cycle)
                else:
                    mylogger.logger.warning("Duty cycle not in range (0.0-100.0): " + str(duty_cycle))
            else:
                mylogger.logger.warning("Color is invalud: " + str(color))
        else:
            key = color
            value = duty_cycle
            super().put(key, value)

    def get(self, color, secure=True):
        if secure:
            if color == "RED" or color == "GREEN" or color == "BLUE":
                dc = super().get(color)
            else:
                mylogger.logger.warning("Color is invalud: " + str(color))
                dc = None
            return dc
        else:
            key = color
            dc = super().get(key)
            return dc

    def config_watcher(self):
        rgb_dict = super().config_watcher(loop=True)
        if rgb_dict["RED"] > 100.0: rgb_dict["RED"] = 100.0
        if rgb_dict["RED"] > 100.0: rgb_dict["RED"] = 100.0
        if rgb_dict["GREEN"] > 100.0: rgb_dict["GREEN"] = 100.0
        if rgb_dict["GREEN"] < 0.0: rgb_dict["GREEN"] = 0.0
        if rgb_dict["BLUE"] < 0.0: rgb_dict["BLUE"] = 0.0
        if rgb_dict["BLUE"] < 0.0: rgb_dict["BLUE"] = 0.0
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
    config_path = str(myfolder) + "/config/rgb_config.json"
    rgb = RGB_config_handler(config_path)

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
