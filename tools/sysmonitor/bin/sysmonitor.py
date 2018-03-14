#!/usr/bin/python

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "../lib"))
import temp
import cpu_usage
import disk_usage
import general_infos
import logged_in_users
import mem_usage

output=""
components_separator="\n"

parser = argparse.ArgumentParser()
parser.add_argument("-a", "--all",  action='store_true', help="show all implemented informations")
parser.add_argument("-t", "--temp",  action='store_true', help="show cpu and gpu temerature")
parser.add_argument("-c", "--cpu",  action='store_true', help="show cpu usage")
parser.add_argument("-d", "--disk",  action='store_true', help="show disk usage")
parser.add_argument("-m", "--memory",  action='store_true', help="show memory usage")
parser.add_argument("-l", "--loggedin",  action='store_true', help="show logged in users")
parser.add_argument("-g", "--general",  action='store_true', help="show general informations")

args = parser.parse_args()
_all = args.all
_temp = args.temp
_cpu = args.cpu
_disk = args.disk
_memory = args.memory
_loggedin = args.loggedin
_general = args.general

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

if output != "":
    print(output)
else:
    print("HELP: " + str(os.path.basename(os.path.abspath(__file__)))[:-3] + " -h")
