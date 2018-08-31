#!/usr/bin/python3

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
import subprocess
import time

# IMPORT SAHERED SOCKET MEMORY FOR VIRTUAL BUTTONS
try:
    sys.path.append( os.path.join(myfolder, "../../../tools/socketmem/lib/") )
    import clientMemDict
    socketdict = clientMemDict.SocketDictClient()
except Exception as e:
    socketdict = None
    print("Socket client error: " + str(e))

parser = argparse.ArgumentParser()
parser.add_argument("-ol", "--oled", help="Oled service ON or OFF")
parser.add_argument("-sh", "--show",  action='store_true', help="show service status")
parser.add_argument("-re", "--restart",  action='store_true', help="restart oled service")
parser.add_argument("-bu", "--button", help="LEFT / STANDBY / RIGHT / standbyFalse / standbyTrue")
parser.add_argument("-jo", "--joystick", help="LEFT / RIGHT / UP / DOWN /CENTER")
parser.add_argument("-ss", "--set_service", action='store_true', help="set systemd service - boot start...")

args = parser.parse_args()
oled = args.oled
show = args.show
restart = args.restart
button = args.button
joystick = args.joystick
set_service = args.set_service

oled_core_script = "oled_gui_core.py"
set_service_script = os.path.join(myfolder, "../systemd_setup/set_service.bash")

def process_is_run(process_name):
    ps = subprocess.Popen("ps aux | grep -v grep | grep " + str(process_name), shell=True, stdout=subprocess.PIPE)
    stdout_list = ps.communicate()[0]
    if len(stdout_list) != 0:
        #print(stdout_list)
        return True
    else:
        return False

def start():
    # start with systemctl
    process = subprocess.Popen("sudo systemctl is-enabled oled_gui_core", stdout=subprocess.PIPE, shell=True)
    returncode = process.wait()
    output = str(process.stdout.read())
    print("sudo systemctl is-enabled oled_gui_core -> exitcode:{}, stdout:{}".format(returncode, output))
    if "enabled" in output or "disabled" in output:
        print("[start with systemctl] sudo systemctl start oled_gui_core")
        process = subprocess.Popen("sudo systemctl start oled_gui_core", stdout=subprocess.PIPE, shell=True)
        returncode = process.wait()
        output = process.stdout.read()
        print("sudo systemctl start oled_gui_core -> exitcode:{}, stdout:{}".format(returncode, output))
    else:
        # start with custom scripts
        if process_is_run(oled_core_script):
            print(str(oled_core_script) + " already run.")
        else:
            print("[start with custom scripts] Start " + str(oled_core_script))
            cmd = "nohup " + str(os.path.join(myfolder, "start_oled_service.bash")) + " &"
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            while not process_is_run(oled_core_script):
                print("Wait for start")
            else:
                print("SUCCESS")

def stop():
    # start with systemctl
    process = subprocess.Popen("sudo systemctl is-enabled oled_gui_core", stdout=subprocess.PIPE, shell=True)
    returncode = process.wait()
    output = str(process.stdout.read())
    print("sudo systemctl is-enabled oled_gui_core -> exitcode:{}, stdout:{}".format(returncode, output))
    if "enabled" in output or "disabled" in output:
        print("[start with systemctl] sudo systemctl stop oled_gui_core")
        process = subprocess.Popen("sudo systemctl stop oled_gui_core", stdout=subprocess.PIPE, shell=True)
        returncode = process.wait()
        output = process.stdout.read()
        print("sudo systemctl stop oled_gui_core -> exitcode:{}, stdout:{}".format(returncode, output))
    else:
        # start with custom scripts
        if not process_is_run(oled_core_script):
            print(str(oled_core_script) + "is not running")
        else:
            print("[stop with custom scripts] Stop " + str(oled_core_script))
            proc = subprocess.Popen("nohup " + str(os.path.join(myfolder, "stop_oled_service.bash")) + " &", shell=True, stdout=subprocess.PIPE)
            while process_is_run(oled_core_script):
                print("Wait for stop")
            else:
                print("SUCCESS")

def set_buttons(button):
    command = None
    if button.upper() == "RIGHT" or button.upper() == "LEFT" or button.upper() == "STANDBY":
        command = button.upper()
    elif button.lower() == "standbyfalse":
        command = "standbyFalse"
    elif button.lower() == "standbytrue":
        command = "standbyTrue"

    if command is not None:
        socketdict.set_parameter("oled", "sysbuttons", str(command))
    else:
        print("Button is invalid: " + str(command))

def set_joystick(button):
    command = None
    if button.upper() == "RIGHT" or button.upper() == "LEFT" or button.upper() == "UP" \
    or button.upper() == "DOWN" or button.upper() == "CENTER":
        command = button.upper()

    if command is not None:
        print(command)
        socketdict.set_parameter("oled", "joystick", str(command))
    else:
        print("Button is invalid: " + str(command))

def restart_oled_gui_core():
    # restart with systemctl
    process = subprocess.Popen("sudo systemctl is-active oled_gui_core", stdout=subprocess.PIPE, shell=True)
    returncode = process.wait()
    output = str(process.stdout.read())
    print("sudo systemctl is-active oled_gui_core -> exitcode:{}, stdout:{}".format(returncode, output))
    if "active" in output or "inactive" in output:
        print("[restart with systemctl] sudo systemctl restart oled_gui_core")
        process = subprocess.Popen("sudo systemctl restart oled_gui_core", stdout=subprocess.PIPE, shell=True)
        returncode = process.wait()
        output = process.stdout.read()
        print("sudo systemctl restart oled_gui_core -> exitcode:{}, stdout:{}".format(returncode, output))
    else:
        # restart with custom scripts
        print("[restart with custom scripts] Restart oled service")
        stop()
        while process_is_run(oled_core_script):
            print("Waiting for stop process")
        start()
        print("process is start: " + str(process_is_run(oled_core_script)))

def set_service_up_systemd():
    print("Set systemd oled_gui_core service - boot up lounch and so on...")
    output = subprocess.check_output(set_service_script)
    print(str(output.decode("utf-8")))

################################## CHECK ARGS #######################################
# oled on/off
if oled is not None:
    if oled == "ON" or oled == "on":
        start()
    elif oled == "OFF" or oled == "off":
        stop()
    else:
        print("Unknown argument: " + str(oled))

# oled restart
if restart:
    restart_oled_gui_core()

# oled status show
if show:
    status = process_is_run(oled_core_script)
    print("Oled service is run: " + str(status))

# oled virtual button
if button is not None:
    set_buttons(button)

if joystick is not None:
    set_joystick(joystick)

# set systemd service
if set_service:
    set_service_up_systemd()
