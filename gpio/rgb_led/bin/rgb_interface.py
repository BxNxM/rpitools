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

args = parser.parse_args()
R = args.red
G = args.green
B = args.blue

if R is not None:
    if int(R):
        print("Set red: " + str(R))
        rgb.put("RED", int(R))
    else:
        print(str(R) + " is not integer")

if G is not None:
    if int(G):
        print("Set green: " + str(G))
        rgb.put("GREEN", int(G))
    else:
        print(str(G) + " is not integer")

if B is not None:
    if int(B):
        print("Set blue: " + str(B))
        rgb.put("BLUE", int(B))
    else:
        print(str(B) + " is not integer")
