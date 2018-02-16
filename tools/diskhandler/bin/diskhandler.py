#!/usr/bin/python

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(myfolder, "../lib/")
sys.path.append(lib_path)
import mount_connected_disks
import subprocess
import time
import threading
import time

parser = argparse.ArgumentParser()
parser.add_argument("-sge", "--search_get_edit", action='store_true', help="Search devices (/dev/sda*), get label and uuid, set fstab file")
parser.add_argument("-m", "--mount",  action='store_true', help="Mount avaible devices (/media/*)")


args = parser.parse_args()
sge = args.search_get_edit
m = args.mount

def main():
    if sge:
        mount_connected_disks.do_search_get_edit()
    if m:
        mount_connected_disks.mount()

if __name__ == "__main__":
    main()
    time.sleep(1)
    sys.exit(0)
