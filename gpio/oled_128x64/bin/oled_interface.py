#!/usr/bin/python3

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("-o", "--oled", help="Oled service ON or OFF")
parser.add_argument("-sh", "--show",  action='store_true', help="show service status")
parser.add_argument("-r", "--restart",  action='store_true', help="restart oled service")
parser.add_argument("-b", "--button", help="LEFT / OK / RIGHT / standbyFalse / standbyTrue")

args = parser.parse_args()
oled = args.oled
show = args.show
restart = args.restart
button = args.button

oled_core_script = "oled_gui_core.py"
oled_virtual_buttons_file = os.path.join(myfolder, "../lib/.virtual_button_file")

def process_is_run(process_name):
    ps = subprocess.Popen("ps aux | grep -v grep | grep " + str(process_name), shell=True, stdout=subprocess.PIPE)
    stdout_list = ps.communicate()[0]
    if len(stdout_list) != 0:
        #print(stdout_list)
        return True
    else:
        return False

def start():
    if process_is_run(oled_core_script):
        print(str(oled_core_script) + " already run.")
    else:
        print("Start " + str(oled_core_script))
        cmd = "nohup " + str(os.path.join(myfolder, "start_oled_service.bash")) + " &"
        proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        while not process_is_run(oled_core_script):
            print("Wait for start")
        else:
            print("SUCCESS")

def stop():
    if not process_is_run(oled_core_script):
        print(str(oled_core_script) + "is not running")
    else:
        print("Stop " + str(oled_core_script))
        proc = subprocess.Popen("nohup " + str(os.path.join(myfolder, "stop_oled_service.bash")) + " &", shell=True, stdout=subprocess.PIPE)
        while process_is_run(oled_core_script):
            print("Wait for stop")
        else:
            print("SUCCESS")

def buttons(button):
    if button == "RIGHT" or button == "LEFT" or button == "OK":
        with open(oled_virtual_buttons_file, 'w') as f:
            f.write()
        print("Button is set: " + str(button))
    else:
        print("Not valid argunet: " + str(button))

if oled is not None:
    # TODO start oled service if not running
    if oled == "ON" or oled == "on":
        start()
    elif oled == "OFF" or oled == "off":
        # TODO kill oled service
        stop()
    else:
        print("Unknown argument: " + str(oled))

if restart:
    print("Restart oled service")
    stop()
    while process_is_run(oled_core_script):
        print("Waiting for stop process")
    start()
    print("process is start: " + str(process_is_run(oled_core_script)))

if show:
    status = process_is_run(oled_core_script)
    print("Oled service is run: " + str(status))

if button is not None:
    if button == "RIGHT" or button == "LEFT" or button == "OK" or button == "standbyFalse" or button == "standbyTrue":
        with open(oled_virtual_buttons_file, 'w') as f:
            f.write(button)
            print("Button is set: " + str(button))
    else:
        print("Button is invalid: " + str(button))
