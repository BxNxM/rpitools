#!/usr/bin/python

import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(myfolder, "../lib/")
sys.path.append(lib_path)
import format_disk
import mount_connected_disks
import storage_structure_handler
import subprocess
import time
import threading
import prepare_and_format_blockdevice
import BlockDeviceHandler
try:
    confhandler_path = os.path.join(myfolder,"../../../autodeployment/lib/")
    sys.path.append(confhandler_path)
    import ConfigHandler
    cfg = ConfigHandler.init()
except Exception as e:
    print("Import config handler failed: " + str(e))

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--search_get_edit", action='store_true', help="Search devices (/dev/sda*), get label and uuid, set fstab file")
parser.add_argument("-m", "--mount",  action='store_true', help="Mount avaible devices (/media/*)")
parser.add_argument("-f", "--format_ext4",  action='store_true', help="Format device for ext4 filesystem")
parser.add_argument("-l", "--listdevs",  action='store_true', help="List connected devices with seversal commands")
parser.add_argument("-t", "--storage_structure",  action='store_true', help="Set storage folder structure")
parser.add_argument("-w", "--show_storage_structure",  action='store_true', help="Show storage folder structure")
parser.add_argument("-p", "--prepare_disks",  action='store_true', help="Prepare disks whick contains diskconf.json")
parser.add_argument("-c", "--change_dev_name",  action='store_true', help="Change disk label name")

args = parser.parse_args()
sge = args.search_get_edit
mount = args.mount
form = args.format_ext4
listdev = args.listdevs
storage = args.storage_structure
show_storage_structure = args.show_storage_structure
prepare_disks = args.prepare_disks
change_dev_name =args.change_dev_name

def pre_check(info="CKECK"):
    state, msg = BlockDeviceHandler.is_any_device_avaible()
    if not state:
        print("{} There are no connected devices: {}".format(info, msg))
        sys.exit(444)

def main():
    if sge:
        pre_check("do_search_get_edit")
        mount_connected_disks.do_search_get_edit()
    if mount:
        pre_check("mount")
        mount_connected_disks.mount()
    if form:
        pre_check("format_disk")
        format_disk.main()
    if listdev:
        pre_check("hum_readable_list_devices")
        format_disk.hum_readable_list_devices()
    if storage:
        if str(cfg.get(section="STORAGE", option="external")).lower() == "true":
            set_extarnal_storage = True
        else:
            set_extarnal_storage = False
        external_storage_label = str(cfg.get(section="STORAGE", option="label")).rstrip()
        storage_structure_handler.create_storage_stucrure(set_extarnal_storage, external_storage_label)
    if show_storage_structure:
        if str(cfg.get(section="STORAGE", option="external")).lower() == "true":
            set_extarnal_storage = True
        else:
            set_extarnal_storage = False
        external_storage_label = str(cfg.get(section="STORAGE", option="label")).rstrip()
        text = storage_structure_handler.get_storage_structure_folders(set_extarnal_storage, external_storage_label)
    if prepare_disks:
        pre_check("prepare_block_device")
        if str(cfg.get(section="STORAGE", option="external")).lower() == "true":
            prepare_and_format_blockdevice.prepare_block_device()
        else:
            print("For automatic disk format based on diskconf.json switch STORAGE -> external True in rpitools_config.conf")
    if change_dev_name:
        pre_check("change_dev_name")
        format_disk.hum_readable_list_devices()
        device = raw_input("Select device path:\t/dev/sdaX: ")
        name = raw_input("New disk label name: ")
        mount_connected_disks.set_get_device_name(device, name)

if __name__ == "__main__":
    main()
    time.sleep(1)
    sys.exit(0)
