#!/usr/bin/python

import LocalMachine
import BlockDeviceHandler

def hum_readable_list_devices(full_info=False):
    if full_info:
        cmd="lsblk"
        exit_code, stdout, stderr = LocalMachine.run_command(cmd)
        if exit_code == 0:
            print("[CMD] " + str(cmd))
            print(stdout)
            print("\n")
        cmd="blkid"
        exit_code, stdout, stderr = LocalMachine.run_command(cmd)
        if exit_code == 0:
            print("[CMD] " + str(cmd))
            print(stdout)
            print("\n")
        cmd="sudo fdisk -l | grep -v grep | grep /dev/sd"
        exit_code, stdout, stderr = LocalMachine.run_command(cmd)
        if exit_code == 0:
            print("[CMD] " + str(cmd))
            print(stdout)

    devices_list = BlockDeviceHandler.list_connected_devices()
    for device in devices_list:
        device_info = BlockDeviceHandler.get_device_info_data(device)
        for key, value in device_info.items():
            sep_len = 12 - len(key)
            sep = " "*sep_len
            print("\t{}:{}{}".format(key, sep, value))

def main():
    hum_readable_list_devices()
    print("\nFormat your disk to ext4 filesystem:")
    device = raw_input("Device (ex. /dev/sda1): ")
    label = raw_input("Wanted label (ex. what wou want - ex. drive): ")
    BlockDeviceHandler.format_ex4(device, label)

if __name__ == "__main__":
    main()
