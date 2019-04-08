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
import rpitools_services_list
import LocalMachine
import HeaderTimeDateUser
from Colors import Colors
import MemDictHandler
try:
    MemDictHandler.set_value_metadata_info("=== ")
except:
    pass

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
parser.add_argument("-s", "--services",  action='store_true', help="show rpitools services")
parser.add_argument("-e", "--export",  action='store_true', help="save measured health data to memdict")

args = parser.parse_args()
_all = args.all
_temp = args.temp
_cpu = args.cpu
_disk = args.disk
_memory = args.memory
_loggedin = args.loggedin
_general = args.general
_loop = args.loop
_services = args.services
_export = args.export

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

def main(_all, _temp, _cpu, _memory, _disk, _loggedin, _general, _services):
    global is_interrupted, _export
    output = ""
    try:
        if _temp or _all:
            try:
                output += temp.main(_export) + components_separator
            except Exception as e:
                output += "temp request error: " + str(e)
        if _cpu or _all:
            try:
                output += cpu_usage.main(_export) + components_separator
            except Exception as e:
                output += "cpu usage request error: " + str(e)
        if _memory or _all:
            try:
                output += mem_usage.main(_export) + components_separator
            except Exception as e:
                output += "mem usage request error: " + str(e)
        if _disk or _all:
            try:
                output += disk_usage.main(_export) + components_separator
            except Exception as e:
                output += "disk usage request error: " + str(e)
        if _loggedin or _all:
            try:
                output += logged_in_users.main() + components_separator
            except Exception as e:
                output += "logged-in in users list request error: " + str(e)
        if _general or _all:
            try:
                output += general_infos.main() + components_separator
            except Exception as e:
                output += "general network and system info request error: " + str(e)
        if _services or _all:
            try:
                output += rpitools_services_list.main(_export) + components_separator
            except Exception as e:
                output += "rpitools services list request error: " + str(e)
        if output != "":
            header = HeaderTimeDateUser.main()
            output = header + "\n" + output.rstrip()
    except KeyboardInterrupt as e:
        is_interrupted = True
        sys.exit(0)
    finally:
        return output

# MAIN SCOPE
logo()
while True:
    output = main(_all, _temp, _cpu, _memory, _disk, _loggedin, _general, _services)

    if output != "":
        if _loop:
            print(LocalMachine.run_command_safe("clear"))
        print(output)
    else:
        _all = True
        output = main(_all, _temp, _cpu, _memory, _disk, _loggedin, _general, _services)
        if _loop:
            print(LocalMachine.run_command_safe("clear"))
        print(output)

    if not _loop or is_interrupted:
        print("Goodbye :)")
        break
    else:
        try:
            time.sleep(0.1)
        except KeyboardInterrupt:
            print("Goodbye :)")
            break
