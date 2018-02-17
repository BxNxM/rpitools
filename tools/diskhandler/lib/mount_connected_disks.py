#!/usr/bin/python

#http://www.bobjectsinc.com/tinycomputers/raspbian-automatically-mount-usb-drives/
import LocalMachine
import os
import sys
import getpass
USER = "pi"

def error_msg(text):
    print("[ !!! ] " + str(text))

def list_connected_devices():
    cmd = "ls /dev/sd*"
    textmatrix = ""
    devices = []

    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    if exitcode == 0:
        textmatrix = LocalMachine.text_to_matrix_converter(stdout)
        for line in textmatrix:
            digit = line[0][-1]                                         # check if didgit is the last character ex. /dev/sda1
            if digit.isdigit():
                devices.append(line[0])
    else:
        error_msg("Command: {} return with error code: {}".format(cmd, exitcode))
        error_msg("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
        sys.exit(1)
    return devices

def get_label_uuid(devices):
    label_uuid_matrix = []
    for device in devices:
        cmd = "sudo blkid " + str(device)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        if exitcode == 0:
            textmatrix = LocalMachine.text_to_matrix_converter(stdout)
            for line in textmatrix:
                label = line[1].split("=")[1]
                label = label[1:-1]
                uuid = line[2].split("=")[1]
                uuid = uuid[1:-1]
                label_uuid_matrix.append([label, uuid])
        else:
            error_msg("Command: {} return with error code: {}".format(cmd, exitcode))
            error_msg("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
    return label_uuid_matrix

def edit_fstab_create_mount_points(label_uuid_matrix, fstab_path="/etc/fstab"):
    global USER

    cmd_lines= []
    for label_uuid in label_uuid_matrix:
        uuid = label_uuid[1]
        label = label_uuid[0]
        cmd = "UUID={} /media/{} auto defaults,auto,noatime,nofail,users,rw, 0 1".format(uuid, label)          # ext4 mount - done
        cmd_lines.append([cmd, uuid, label])

    for cmd_ in cmd_lines:
        # check device is already added to the system, and make override protection
        enable = False
        uuid_is_exists = "cat {} | grep -v grep | grep '{}'".format(fstab_path, cmd_[1] + " ")
        print(uuid_is_exists)
        label_is_exists = "cat {} | grep -v grep | grep '{}'".format(fstab_path, cmd_[2] + " ")
        exitcode, stdout, stderr = LocalMachine.run_command(uuid_is_exists)
        if exitcode != 0 and stderr == "" and stdout == "":
            print("\tnew device unique id {}".format(cmd_[1]))
            exitcode, stdout, stderr = LocalMachine.run_command(label_is_exists)
            if exitcode != 0 and stderr == "" and stdout == "":
                print("\tnew device name {}".format(cmd_[2]))
                enable = True
            else:
                print("\tdevice name is already exists in fstab {} !!!".format(cmd_[2]))
        else:
            print("\tdevice unique id is already exists in fstab {} !!!".format(cmd_[1]))


        if enable:
            print("+++> ADDING NEW DEVICE IS ENABLE")
            check_cmd = "cat {} | grep -v grep | grep '{}'".format(fstab_path, cmd_[0])
            exitcode, stdout, stderr = LocalMachine.run_command(check_cmd)
            if exitcode != 0 and stdout == "":
                print("line not exists: {}".format(cmd_[0]))
                print("ADD TO " + str(fstab_path))
                # edit fstab file
                add_cmd = "sudo echo '{}' >> {}".format(cmd_[0], fstab_path)
                exitcode, stdout, stderr = LocalMachine.run_command(add_cmd)
                if exitcode == 0:
                    print("{} added succesfully!".format(cmd_[0]))
                else:
                    error_msg("Command: {} return with error code: {}".format(cmd, exitcode))
                    error_msg("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
            else:
                print("line exists: {}".format(cmd_[0]))

        # create mount point
        label = cmd_[2]
        if not os.path.isdir("/media/"+str(label)):
            print("Create /media/" + str(label))
            os.makedirs("/media/"+str(label))
            print("chmod 0765 /media/"+str(label))
            os.chmod("/media/"+str(label), 0765)
            print("chmod " + str(USER))
            LocalMachine.run_command("chown " + USER + " /media/"+str(label))
        else:
            print("/media/" + str(label) + " already exists")

def mount_all_devices():
    media_dirs = []
    for dirname, dirnames, filenames in os.walk('/media/'):
        media_dirs = dirnames
        break

    for actualdir in media_dirs:
        is_mounted_cmd = "grep -qs '/media/{}' /proc/mounts".format(actualdir)
        exitcode, stdout, stderr = LocalMachine.run_command(is_mounted_cmd)
        if exitcode == 0:
            print("/media/{} is already mounted".format(actualdir))
        elif exitcode == 1:
            print("/media/{} mount".format(actualdir))
            mount_cmd = "mount /media/" + str(actualdir)
            exitcode, stdout, stderr = LocalMachine.run_command(mount_cmd)
            if exitcode == 0:
                is_mounted_cmd = "grep -qs '/media/{}' /proc/mounts".format(actualdir)
                exitcode, stdout, stderr = LocalMachine.run_command(is_mounted_cmd)
                if exitcode == 0:
                    print("Successfully mounted")
                elif exitcode == 1:
                    print("Fail to mount - may device is not found")
                else:
                    error_msg("EXITCODE: {}\nSTDOUT: {}\nSTDERR:{}".format(exitcode, stdout, stderr))
            else:
                error_msg("Mount failed!")
                error_msg("Command: {} return with error code: {}".format(mount_cmd, exitcode))
                error_msg("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
        else:
            error_msg("Unexpected error!")
            error_msg("Command: {} return with error code: {}".format(is_mounted_cmd, exitcode))
            error_msg("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))

def set_get_device_name(device, name=None):
    if os.path.exists(device):
        if name is None:
            exitcode, stdout, stderr = LocalMachine.run_command("sudo e2label " + str(device))                      #device=/dev/sda1
            if exitcode == 0 and stderr == "" and stdout != "":
                print("Device {} name: {}".format(device, stdout))
                return stdout
            else:
                print("exitcode:{}\nstdout:{}\nstderr:{}".format(exitcode, stdout, stderr))
        else:
            exitcode, stdout, stderr = LocalMachine.run_command("sudo e2label " + str(device) + " " + str(name))
            if exitcode == 0 and stderr == "":
                set_get_device_name(device)
            else:
                print("exitcode:{}\nstdout:{}\nstderr:{}".format(exitcode, stdout, stderr))
    else:
        error_msg("Device is not found " + str(device))


def do_search_get_edit():
    print("Search devices...")
    textm = list_connected_devices()
    print("Get label and uuid...")
    label_uuid_m = get_label_uuid(textm)
    print(label_uuid_m)
    print("Edit fstab file and create mount points...")
    edit_fstab_create_mount_points(label_uuid_m)

def mount():
    print("Mount all devices...")
    mount_all_devices()

if __name__ == "__main__":
    do_search_get_edit()
    mount()

