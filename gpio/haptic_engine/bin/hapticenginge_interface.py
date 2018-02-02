#!/usr/bin/python3

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(myfolder, "../lib/")
sys.path.append(lib_path)
import haptic_engine_core
import subprocess
import time
import threading

parser = argparse.ArgumentParser()
parser.add_argument("-u", "--up", action='store_true', help="HapticEngine UP signel")
parser.add_argument("-d", "--down",  action='store_true', help="HapticEngine DOWN signel")
parser.add_argument("-s", "--soft",  action='store_true', help="HapticEngine SOFT signel")
parser.add_argument("-t", "--tap", action='store_true', help="HapticEngine TAP signel")
parser.add_argument("-dt", "--doubletap", action='store_true', help="HapticEngine DoubleTAP signel")
parser.add_argument("-sn", "--snooze", action='store_true', help="HapticEngine SNOOZE signel")

args = parser.parse_args()
up = args.up
down = args.down
soft = args.soft
tap = args.tap
doubletap = args.doubletap
snooze = args.snooze
hapt = None

def init_haptic_engine_object():
    global hapt
    hapt = haptic_engine_core.HapticEngine()

def run_interface(option=None):
    if up or option == "up":
        th = threading.Thread(target=hapt.UP())
        th.start()
    if down or option == "down":
        th = threading.Thread(target=hapt.DOWN())
        th.start()
    if soft or option == "soft":
        th = threading.Thread(target=hapt.SOFT())
        th.start()
    if tap or option == "tap":
        th = threading.Thread(target=hapt.TAP())
        th.start()
    if doubletap or option == "doubletap":
        th = threading.Thread(target=hapt.DoubleTAP())
        th.start()
    if snooze or option == "snooze":
        th = threading.Thread(target=hapt.SNOOZE())
        th.start()

init_haptic_engine_object()
if __name__ == "__main__":
    run_interface()
