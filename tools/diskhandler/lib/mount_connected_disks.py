#!/usr/bin/python

#http://www.bobjectsinc.com/tinycomputers/raspbian-automatically-mount-usb-drives/
import LocalMachine
import os
import getpass
USER = "pi"

def list_connected_devices():
    cmd = "ls /dev/sda*"
    textmatrix = ""
    devices = []

    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    if exitcode == 0:
        textmatrix = LocalMachine.text_to_matrix_converter(stdout)
        for line in textmatrix:
            if line[0] != "/dev/sda":
                devices.append(line[0])
    else:
        print("Command: {} return with error code: {}".format(cmd, exitcode))
        print("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
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
            print("Command: {} return with error code: {}".format(cmd, exitcode))
            print("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
    return label_uuid_matrix

def edit_fstab(label_uuid_matrix, fstab_path="/etc/fstab"):
    global USER

    cmd_lines= []
    for label_uuid in label_uuid_matrix:
        uuid = label_uuid[1]
        label = label_uuid[0]
        cmd = "UUID={} /media/{} auto defaults,auto,umask=000,users,rw,uid=pi,gid=pi 0 0".format(uuid, label)
        cmd_lines.append(cmd)

    for cmd_ in cmd_lines:
        check_cmd = "cat {} | grep -v grep | grep '{}'".format(fstab_path, cmd_)
        exitcode, stdout, stderr = LocalMachine.run_command(check_cmd)
        if exitcode != 0 and stdout == "":
            print("line not exists: {}".format(cmd_))
            print("ADD TO " + str(fstab_path))
            # edit fstab file
            add_cmd = "sudo echo '{}' >> {}".format(cmd_, fstab_path)
            exitcode, stdout, stderr = LocalMachine.run_command(add_cmd)
            if exitcode == 0:
                print("{} added succesfully!".format(cmd_))
            else:
                print("Command: {} return with error code: {}".format(cmd, exitcode))
                print("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
        else:
            print("line exists: {}".format(cmd_))

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

def mount_all_devices():
    #grep -qs '/media/BNM' /proc/mounts
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
                print("Successfully mounted")
            else:
                print("Mount failed!")
                print("Command: {} return with error code: {}".format(cmd, exitcode))
                print("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))
        else:
            print("Unexpected error!")
            print("Command: {} return with error code: {}".format(cmd, exitcode))
            print("STDOUT: {}\nSTDERR:{}".format(stdout, stderr))

if __name__ == "__main__":
    print("Search devices...")
    textm = list_connected_devices()
    print("Get label and uuid...")
    label_uuid_m = get_label_uuid(textm)
    print(label_uuid_m)
    print("Edit fstab file and create mount points...")
    edit_fstab(label_uuid_m)
    print("Mount all devices...")
    mount_all_devices()
