#!/usr/bin/python

import LocalMachine

def list_devices():
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

def format_ex4(device, label):
    cmd = "sudo mkfs.ext4 {} -L {}".format(device, label)
    exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    if exit_code == 0:
        print("[CMD] " + str(cmd))
        print(stdout)
        print("\n")
    else:
        print("EXITCODE:{}\nSTDOUT:{}\nSTDERR:{}\n".format(exit_code, stdout, stderr))

def main():
    list_devices()
    print("\nFormat your disk to ext4 filesystem:")
    device = raw_input("Device (ex. /dev/sda1): ")
    label = raw_input("Wanted label (ex. what wou want - ex. drive): ")
    format_ex4(device, label)

if __name__ == "__main__":
    main()
