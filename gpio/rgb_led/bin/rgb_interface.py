#!/usr/bin/python3

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "../lib/"))
import ConfigHandler

config_path = os.path.join(myfolder, "../lib/config/rgb_config.json")
rgb = ConfigHandler.RGB_config_handler(config_path)

parser = argparse.ArgumentParser()
parser.add_argument("-r", "--red", help="RED component 0-100")
parser.add_argument("-g", "--green", help="GREEN component 0-100")
parser.add_argument("-b", "--blue",  help="BLUE component 0-100")
parser.add_argument("-s", "--service",  help="led service ON / OFF")
parser.add_argument("-l", "--led",  help="led ON / OFF")

args = parser.parse_args()
R = args.red
G = args.green
B = args.blue
led_status = args.led
service_status = args.service

if R is not None:
    if 100 >= int(R) >= 0:
        print("Set red: " + str(R))
        rgb.put("RED", int(R))
    else:
        print(str(R) + " is not integer")

if G is not None:
    if 100 >= int(G) >= 0:
        print("Set green: " + str(G))
        rgb.put("GREEN", int(G))
    else:
        print(str(G) + " is not integer")

if B is not None:
    if 100 >= int(B) >= 0:
        print("Set blue: " + str(B))
        rgb.put("BLUE", int(B))
    else:
        print(str(B) + " is not integer")

if led_status is not None:
    if led_status == "ON" or led_status == "OFF":
        rgb.put("LED", led_status, secure=False)
    else:
        print("Invalid input (ON/OFF): " + str(led_status))

if service_status is not None:
    if service_status == "ON" or service_status == "OFF":
        rgb.put("SERVICE", service_status, secure=False)
        print("rgb_led_controller.py shutdown")
    else:
        print("Invalid input (ON/OFF): " + str(led_status))



