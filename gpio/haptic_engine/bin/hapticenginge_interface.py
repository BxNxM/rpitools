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

hapt = haptic_engine_core.HapticEngine()

if up:
    hapt.UP()
if down:
    hapt.DOWN()
if soft:
    hapt.SOFT()
if tap:
    hapt.TAP()
if doubletap:
    hapt.DoubleTAP()
if snooze:
    hapt.SNOOZE()
