#!/usr/bin/python3

import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "../lib/"))
import LedHandler
import ConfigHandler
import LogHandler
mylogger = LogHandler.LogHandler("rgb_led_controller")

def rgb_config_manager():
    # set config handler
    config_path = os.path.join(myfolder, "../lib/config/rgb_config.json")
    rgb = ConfigHandler.RGB_config_handler(config_path)

    # set pins
    green = LedHandler.LedHandler(channel=12)
    red = LedHandler.LedHandler(channel=32)
    blue = LedHandler.LedHandler(channel=33)

    #ledstate init
    led_state = ""

    # init service status on config
    rgb.put("SERVICE", "ON", secure=False)

    while True:
        try:
            rgb_dict = rgb.config_watcher()
            if rgb_dict is not None:
                red.set_dc_with_gradient(rgb_dict["RED"])
                green.set_dc_with_gradient(rgb_dict["GREEN"])
                blue.set_dc_with_gradient(rgb_dict["BLUE"])
                # start led
                if rgb_dict["LED"] != "ON" and led_state != rgb_dict["LED"]:
                    led_state = rgb_dict["LED"]
                    red.stop()
                    green.stop()
                    blue.stop()
                # stop led
                elif rgb_dict["LED"] == "ON" and led_state != rgb_dict["LED"]:
                    led_state = rgb_dict["LED"]
                    red.start()
                    green.start()
                    blue.start()

                if rgb_dict["SERVICE"] != "ON":
                    red.stop()
                    green.stop()
                    blue.stop()
                    red.__del__()
                    green.__del__()
                    blue.__del__()
                    break
        except KeyboardInterrupt as e:
            mylogger.logger.info("Program is existing: Ctrl-C")

def rgb_demo():
    green = LedHandler.LedHandler(channel=12)
    red = LedHandler.LedHandler(channel=32)
    blue = LedHandler.LedHandler(channel=33)

    green.set_dc_with_gradient(10)
    red.set_dc_with_gradient(10)
    blue.set_dc_with_gradient(10)

    input("Press ENTER to exit")

if __name__ == "__main__":
    #rgb_demo()
    rgb_config_manager()

