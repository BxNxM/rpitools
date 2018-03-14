#!/usr/bin/python

import argparse
import os
import sys
import time
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "../lib"))
sys.path.append(os.path.join(myfolder, "../lib/api"))
import temp
import cpu_usage
import disk_usage
import general_infos
import logged_in_users
import mem_usage
import LocalMachine
from Colors import Colors

components_separator="\n"
is_interrupted = False

parser = argparse.ArgumentParser()
parser.add_argument("-a", "--all",  action='store_true', help="show all implemented informations")
parser.add_argument("-t", "--temp",  action='store_true', help="show cpu and gpu temerature")
parser.add_argument("-c", "--cpu",  action='store_true', help="show cpu usage")
parser.add_argument("-d", "--disk",  action='store_true', help="show disk usage")
parser.add_argument("-m", "--memory",  action='store_true', help="show memory usage")
parser.add_argument("-l", "--loggedin",  action='store_true', help="show logged in users")
parser.add_argument("-g", "--general",  action='store_true', help="show general informations")
parser.add_argument("-o", "--loop",  action='store_true', help="show informations in loop")

args = parser.parse_args()
_all = args.all
_temp = args.temp
_cpu = args.cpu
_disk = args.disk
_memory = args.memory
_loggedin = args.loggedin
_general = args.general
_loop = args.loop

def logo():
    text=Colors.RED + '''
 _____    _____    _____   _                     _       
|  __ \  |  __ \  |_   _| | |                   | |      
| |__) | | |__) |   | |   | |_    ___     ___   | |  ___ 
''' + Colors.YELLOW + '''|  _  /  |  ___/    | |   | __|  / _ \   / _ \  | | / __|
''' + Colors.GREEN + '''| | \ \  | |       _| |_  | |_  | (_) | | (_) | | | \__ \\
|_|  \_\ |_|      |_____|  \__|  \___/   \___/  |_| |___/system monitor
''' + Colors.NC
    print(text)

def main(_all, _temp, _cpu, _memory, _disk, _loggedin, _general):
    global is_interrupted
    output = ""
    try:
        if _temp or _all:
            output += temp.main() + components_separator
        if _cpu or _all:
            output += cpu_usage.main() + components_separator
        if _memory or _all:
            output += mem_usage.main() + components_separator
        if _disk or _all:
            output += disk_usage.main() + components_separator
        if _loggedin or _all:
            output += logged_in_users.main() + components_separator
        if _general or _all:
            output += general_infos.main() + components_separator
    except KeyboardInterrupt as e:
        is_interrupted = True
        sys.exit(0)
    finally:
        return output

# MAIN SCOPE
logo()
while True:
    output = main(_all, _temp, _cpu, _memory, _disk, _loggedin, _general)

    if output != "":
        print(LocalMachine.run_command_safe("clear"))
        print(output)
    else:
        _all = True
        output = main(_all, _temp, _cpu, _memory, _disk, _loggedin, _general)
        print(LocalMachine.run_command_safe("clear"))
        print(output)

    if not _loop or is_interrupted:
        print("Goodbye :)")
        break
    else:
        try:
            time.sleep(0.2)
        except KeyboardInterrupt:
            print("Goodbye :)")
            break
