#!/usr/bin/python

#http://www.bobjectsinc.com/tinycomputers/raspbian-automatically-mount-usb-drives/
import LocalMachine
import os
import sys
import getpass
import BlockDeviceHandler
# TODO: get user name from config file!
USER = "pi"

def error_msg(text):
    print("[ !!! ] " + str(text))

def edit_fstab_create_mount_point(device_info_dict, fstab_path="/etc/fstab"):
    global USER

    uuid = device_info_dict["uuid"]
    label = device_info_dict["label"]
    cmd = "UUID={} /media/{} auto defaults,auto,noatime,nofail,users,rw, 0 1".format(uuid, label)          # ext4 mount - done

    # check device is already added to the system, and make override protection
    enable = False
    uuid_is_exists = "cat {} | grep -v grep | grep '{}'".format(fstab_path, uuid + " ")
    print(uuid_is_exists)
    label_is_exists = "cat {} | grep -v grep | grep '{}'".format(fstab_path, label + " ")
    exitcode, stdout, stderr = LocalMachine.run_command(uuid_is_exists)
    if exitcode != 0 and stderr == "" and stdout == "":
        print("\tnew device unique id {}".format(uuid))
        exitcode, stdout, stderr = LocalMachine.run_command(label_is_exists)
        if exitcode != 0 and stderr == "" and stdout == "":
            print("\tnew device name {}".format(label))
            enable = True
        else:
            print("\tdevice name is already exists in fstab {} !!!".format(label))
    else:
        print("\tdevice unique id is already exists in fstab {} !!!".format(uuid))


    if enable:
        print("+++> ADDING NEW DEVICE IS ENABLE")
        check_cmd = "cat {} | grep -v grep | grep '{}'".format(fstab_path, cmd)
        exitcode, stdout, stderr = LocalMachine.run_command(check_cmd)
        if exitcode != 0 and stdout == "":
            print("line not exists: {}".format(cmd))
            print("ADD TO " + str(fstab_path))
            # edit fstab file
            add_cmd = "sudo echo '{}' >> {}".format(cmd, fstab_path)
            exitcode, stdout, stderr = LocalMachine.run_command(add_cmd)
            if exitcode == 0:
                print("{} added succesfully!".format(cmd))
            else:
                error_msg("Command: {} return with error code: {}".format(cmd, exitcode))
                error_msg("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
        else:
            print("line exists: {}".format(cmd))

    # create mount point
    if not os.path.isdir("/media/"+str(label)):
        print("Create /media/" + str(label))
        os.makedirs("/media/"+str(label))
        print("chmod 0765 /media/"+str(label))
        os.chmod("/media/"+str(label), 0765)
        print("chmod " + str(USER))
        LocalMachine.run_command("chown " + USER + " /media/"+str(label))
    else:
        print("/media/" + str(label) + " already exists")

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
    device_list = BlockDeviceHandler.list_connected_devices()
    print("Get label and uuid...")
    for device in device_list:
        device_info_dict = BlockDeviceHandler.get_device_info_data(device)
        print(device_info_dict)
        print("Edit fstab file and create mount points...")
        edit_fstab_create_mount_point(device_info_dict)

def mount():
    print("Mount all devices...")
    BlockDeviceHandler.mount_all_devices()

if __name__ == "__main__":
    do_search_get_edit()
    mount()

