import LocalMachine
import mount_connected_disks
import os
import sys

def check_exitcode(cmd, exitcode, stderr):
    if exitcode != 0:
        print("command {} failed [{}]: {}".format(cmd, exitcode, stderr))
        sys.exit(1)
    else:
        print("command {} success".format(cmd))

def get_device_info_data(device):
    device_info_dict = {}
    cmd = "sudo blkid " + str(device)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    check_exitcode(cmd, exitcode, stderr)
    dev_info = stdout.split(" ")
    device_info_dict["path"] = dev_info[0].replace(':', '', 1)
    device_info_dict["label"] = dev_info[1].split("=")[1].replace('"', '', 2)
    device_info_dict["uuid"] = dev_info[2].split("=")[1].replace('"', '', 2)
    device_info_dict["filesystem"] = dev_info[3].split("=")[1].replace('"', '', 2)
    return device_info_dict

def device_is_mounted(dev_path):
    cmd = "grep -qs '{} ' /proc/mounts".format(dev_path)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    if exitcode == 0:
        return True
    else:
        return False

def premount_device(dev):
    dev_info_dict = get_device_info_data(dev)
    premount_path = "/media/pre_" + dev_info_dict['label']
    if not os.path.exists(premount_path):
        print("Mount point not exists - create: " + str(premount_path))
        cmd = "sudo mkdir -p " + str(premount_path)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
    if not device_is_mounted(premount_path):
        print("PreMount device " + str(dev_info_dict['path']))
        cmd = "sudo mount -t {} {} {}".format(dev_info_dict['filesystem'], dev_info_dict['path'], premount_path)
        print(cmd)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
    else:
        print("Already mounted " + str(dev_info_dict['path']))
    return premount_path

def unmount_all_premounted_devices():
    premounted_devices_list = []
    cmd = "ls -1 /media/"
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    check_exitcode(cmd, exitcode, stderr)
    devices_list = stdout.split('\n')
    for dev in devices_list:
        dev = "/media/" + str(dev)
        if "pre_" in dev:
            premounted_devices_list.append(dev)
    print("premounted devices: " + str(premounted_devices_list))
    for dev in premounted_devices_list:
        if device_is_mounted(dev):
            cmd = "sudo umount " + str(dev)
            exitcode, stdout, stderr = LocalMachine.run_command(cmd)
            check_exitcode(cmd, exitcode, stderr)
        else:
            print("{} not mounted".format(dev))
        cmd = "rm -rf "  + str(dev)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
