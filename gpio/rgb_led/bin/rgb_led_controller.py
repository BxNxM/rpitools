#!/usr/bin/python3

import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "../lib/"))
import LedHandler
import ConfigHandler

def rgb_config_manager():
    config_path = os.path.join(myfolder, "../lib/config/rgb_config.json")
    rgb = ConfigHandler.RGB_config_handler(config_path)

    green = LedHandler.LedHandler(channel=12)
    red = LedHandler.LedHandler(channel=32)
    blue = LedHandler.LedHandler(channel=33)

    while True:
        try:
            rgb_dict = rgb.config_watcher()
            if rgb_dict is not None:
                red.set_dc_with_gradient(rgb_dict["RED"])
                green.set_dc_with_gradient(rgb_dict["GREEN"])
                blue.set_dc_with_gradient(rgb_dict["BLUE"])
        except KeyboardInterrupt as e:
            print("Program is existing: Ctrl-C")

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

