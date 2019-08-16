#!/usr/bin/python3

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
import subprocess
import time

def rpienv_source():
    import subprocess
    if not os.path.exists(str(myfolder) + '/.rpienv'):
        print("[ ENV ERROR ] " + str(myfolder) + "/.rpienv path not exits!")
        sys.exit(1)
    command = ['bash', '-c', 'source ' + str(myfolder) + '/.rpienv -s && env']
    proc = subprocess.Popen(command, stdout = subprocess.PIPE)
    for line in proc.stdout:
        if type(line) is bytes:
            line = line.decode("utf-8")
        try:
            name = line.partition("=")[0]
            value = line.partition("=")[2]
            if type(value) is unicode:
                value = value.encode('ascii','ignore')
            value = value.rstrip()
            os.environ[name] = value
        except Exception as e:
            if "name 'unicode' is not defined" != str(e):
                print(e)
    proc.communicate()
rpienv_source()

# IMPORT SAHERED SOCKET MEMORY FOR VIRTUAL BUTTONS
try:
    clientmemdict_path = os.path.join(os.path.dirname(os.environ['CLIENTMEMDICT']))
    sys.path.append( clientmemdict_path )
    import clientMemDict
    socketdict = clientMemDict.SocketDictClient()
except Exception as e:
    socketdict = None
    print("Socket client error: " + str(e))

parser = argparse.ArgumentParser()
parser.add_argument("-o", "--oled", help="Oled service ON or OFF")
parser.add_argument("-s", "--show",  action='store_true', help="show service status")
parser.add_argument("-r", "--restart",  action='store_true', help="restart oled service")
parser.add_argument("-b", "--button", help="LEFT / STANDBY / RIGHT / standbyFalse / standbyTrue")
parser.add_argument("-j", "--joystick", help="LEFT / RIGHT / UP / DOWN /CENTER")

args = parser.parse_args()
oled = args.oled
show = args.show
restart = args.restart
button = args.button
joystick = args.joystick

oled_core_script = "oled_gui_core.py"

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

