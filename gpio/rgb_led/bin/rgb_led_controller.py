#!/usr/bin/python3

import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "../lib/"))
import LedHandler
import ConfigHandler
import LogHandler
mylogger = LogHandler.LogHandler("rgb_led_controller")
import time

def rgb_config_manager():
    # set config handler
    rgb = ConfigHandler.RGB_config_handler()

    # set pins
    green = LedHandler.LedHandler(channel=12)
    red = LedHandler.LedHandler(channel=32)
    blue = LedHandler.LedHandler(channel=33)

    #ledstate init
    led_state = ""

    # init service status on config
    rgb.put("SERVICE", "ON", secure=False)
    rgb.put("LED", "OFF", secure=False)

    while True:
        try:
            rgb_dict = rgb.config_watcher()
            mylogger.logger.info("config watcher dict: {}".format(rgb_dict))
            if rgb_dict is not None:
                red.led_dc_controller(rgb_dict["RED"])
                green.led_dc_controller(rgb_dict["GREEN"])
                blue.led_dc_controller(rgb_dict["BLUE"])
                mylogger.logger.info("RGB dict: R{} G{} B{}".format(rgb_dict["RED"], rgb_dict["GREEN"], rgb_dict["BLUE"]))
                # start led
                if rgb_dict["LED"] != "ON" and led_state != rgb_dict["LED"]:
                    mylogger.logger.info("Turn OFF LED")
                    led_state = rgb_dict["LED"]
                    red.stop()
                    green.stop()
                    blue.stop()
                # stop led
                elif rgb_dict["LED"] == "ON" and led_state != rgb_dict["LED"]:
                    mylogger.logger.info("Turn ON LED")
                    led_state = rgb_dict["LED"]
                    red.start()
                    green.start()
                    blue.start()

                if rgb_dict["SERVICE"] != "ON":
                    mylogger.logger.info("Turn OFF service")
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

