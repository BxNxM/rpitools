import LocalMachine
import os
import sys

def module_printer(text):
    printout = "[ BlockDevideHandler ] {}".format(text)
    print(printout)

def check_exitcode(cmd, exitcode, stderr):
    if exitcode != 0:
        module_printer("=> CMD: {} failed [{}]: {}".format(cmd, exitcode, stderr))
        sys.exit(1)
    else:
        module_printer("=> CMD: {} success".format(cmd))

def is_any_device_avaible():
    """ search under /dev with sd prefix for any available devices """
    cmd = "ls /dev/sd*"
    textmatrix = ""
    devices = []

    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    msg = "STDOUT: {} STDERR: {}".format(stdout, stderr)
    if exitcode == 0:
        return True, msg
    else:
        return False, msg

def list_connected_devices():
    """ get block devices from /dev """
    cmd = "ls /dev/sd*"
    textmatrix = ""
    devices = []

    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    if exitcode != 0 and "No such file or directory" in stderr:
        module_printer("\tNO DEVICES WAS FOUND.")
        return []
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

def get_device_info_data(device):
    """ device example: /dev/sda1 """
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

def device_is_mounted(device):
    """ device example: /dev/sda1 or mount point example: /media/device """
    cmd = "grep -qs '{} ' /proc/mounts".format(device)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    if exitcode == 0:
        return True
    else:
        return False

def premount_device(dev):
    """ dev example: /dev/sda1 """
    dev_info_dict = get_device_info_data(dev)
    premount_path = "/media/pre_" + dev_info_dict['label']
    if not os.path.exists(premount_path):
        module_printer("mount point not exists - create: " + str(premount_path))
        cmd = "sudo mkdir -p " + str(premount_path)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
    if not device_is_mounted(premount_path):
        module_printer("premount device " + str(dev_info_dict['path']))
        cmd = "sudo mount -t {} {} {}".format(dev_info_dict['filesystem'], dev_info_dict['path'], premount_path)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
    else:
        module_printer("already mounted " + str(dev_info_dict['path']))
    return premount_path

def mount_device(dev):
    """ dev example: /dev/sda1 """
    dev_info_dict = get_device_info_data(dev)
    mount_path = "/media/" + dev_info_dict['label']
    if not os.path.exists(mount_path):
        module_printer("mount point not exists - create: " + str(mount_path))
        cmd = "sudo mkdir -p " + str(mount_path)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
    if not device_is_mounted(mount_path):
        module_printer("mount device " + str(dev_info_dict['path']))
        cmd = "sudo mount -t {} {} {}".format(dev_info_dict['filesystem'], dev_info_dict['path'], mount_path)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)
    else:
        module_printer("already mounted " + str(dev_info_dict['path']))
    return mount_path

def unmount_device(dev):
    """ device example: /dev/sda1 or mount point example: /media/device """
    cmd = "sudo umount " + str(dev)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    check_exitcode(cmd, exitcode, stderr)

def unmount_all_devices(del_mount_point=False):
    """ unmount all mounted devices """
    mounted_devices_list = []
    cmd = "ls -1 /media/"
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    check_exitcode(cmd, exitcode, stderr)
    devices_list = stdout.split('\n')
    for dev in devices_list:
        if device_is_mounted(dev):
            dev = "/media/" + str(dev)
            mounted_devices_list.append(dev)
    module_printer("mounted devices: " + str(mounted_devices_list))
    for dev in mounted_devices_list:
        if device_is_mounted(dev):
            unmount_device(dev)
        else:
            module_printer("{} not mounted".format(dev))
        if del_mount_point:
            cmd = "rm -rf "  + str(dev)
            exitcode, stdout, stderr = LocalMachine.run_command(cmd)
            check_exitcode(cmd, exitcode, stderr)

def unmount_all_premounted_devices():
    """ serach under /media/ with pre_ prefix and unmount """
    premounted_devices_list = []
    cmd = "ls -1 /media/"
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    check_exitcode(cmd, exitcode, stderr)
    devices_list = stdout.split('\n')
    for dev in devices_list:
        dev = "/media/" + str(dev)
        if "pre_" in dev:
            premounted_devices_list.append(dev)
    module_printer("premounted devices: " + str(premounted_devices_list))
    for dev in premounted_devices_list:
        if device_is_mounted(dev):
            unmount_device(dev)
        else:
            module_printer("{} not mounted".format(dev))
        cmd = "rm -rf "  + str(dev)
        exitcode, stdout, stderr = LocalMachine.run_command(cmd)
        check_exitcode(cmd, exitcode, stderr)

def format_ex4(device, label):
    """ format disk to ext4 linux file format """
    cmd = "sudo mkfs.ext4 {} -L {}".format(device, label)
    exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    if exit_code == 0:
        module_printer("[CMD] " + str(cmd))
        module_printer(stdout)
        module_printer("\n")
    else:
        module_printer("EXITCODE:{}\nSTDOUT:{}\nSTDERR:{}\n".format(exit_code, stdout, stderr))

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
            exitcode, stdout, stderr = LocalMachine.run_command("cat /etc/fstab")
            if exitcode == 0 and actualdir not in stdout:
                print(actualdir + " not in /etc/fstab")
                print("\tSkipping mount...")
                return
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
