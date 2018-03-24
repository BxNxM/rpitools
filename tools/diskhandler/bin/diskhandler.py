#!/usr/bin/python

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(myfolder, "../lib/")
sys.path.append(lib_path)
import format_disk
import mount_connected_disks
import subprocess
import time
import threading
import time

parser = argparse.ArgumentParser()
parser.add_argument("-sge", "--search_get_edit", action='store_true', help="Search devices (/dev/sda*), get label and uuid, set fstab file")
parser.add_argument("-m", "--mount",  action='store_true', help="Mount avaible devices (/media/*)")
parser.add_argument("-f", "--format_ext4",  action='store_true', help="Format device for ext4 filesystem")
parser.add_argument("-l", "--listdevs",  action='store_true', help="List connected devices with seversal commands")

args = parser.parse_args()
sge = args.search_get_edit
m = args.mount
f = args.format_ext4
l = args.listdevs

def pre_check():
    state, msg = mount_connected_disks.is_any_device_avaible()
    if not state:
        print("There are no connected devices: " + str(msg))
        sys.exit(444)

def main():
    if sge:
        mount_connected_disks.do_search_get_edit()
    if m:
        mount_connected_disks.mount()
    if f:
        format_disk.main()
    if l:
        format_disk.list_devices()

if __name__ == "__main__":
    pre_check()
    main()
    time.sleep(1)
    sys.exit(0)
