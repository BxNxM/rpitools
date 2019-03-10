#!/usr/bin/python

import LocalMachine
import os
import sys
import grp
import pwd
import BlockDeviceHandler
from Colors import Colors
pathname = os.path.dirname(sys.argv[0])
default_storage_folders = ["/UserSpace", "/SharedSpace", "/OtherSpace"]
storage_folders_groups = [ "rpitools_admin", "rpitools_user", "rpitools_admin"]
default_storage_root = "/media/virtaul_storage"

def console_out(msg):
    print("{}[STORAGE]{} {}".format(Colors.YELLOW, Colors.NC, msg))

def get_storage_root_and_base_path_list(set_extarnal_storage, external_storage_label):
    global default_storage_folders
    global default_storage_root
    path_list = []

    if set_extarnal_storage:
        storage_root_path = "/media/" + str(external_storage_label)
        if not os.path.exists(storage_root_path):
            console_out("Storage not exists! -> " + str(storage_root_path))
            sys.exit(1)
        else:
            migrate_from_internal_to_external_storage(default_storage_root, storage_root_path, default_storage_folders)
    else:
        storage_root_path = default_storage_root

    for folder in default_storage_folders:
        path_list.append(str(storage_root_path) + folder)
    return storage_root_path, path_list

def migrate_from_internal_to_external_storage(default_storage_root, external_storage_root, default_storage_folders):
    if not os.path.exists(default_storage_root):
        return False
    default_storage_folder_content = os.listdir(default_storage_root)
    linking_is_required = False
    for content in default_storage_folder_content:
        abs_path = default_storage_root + os.sep + content
        if os.path.isdir(abs_path) and not os.path.islink(abs_path):
            cmd = "mv " + str(abs_path) + " " + str(external_storage_root)
            console_out("Migrate storage from {} to {}".format(default_storage_root, external_storage_root))
            exit_code, stdout, stderr = LocalMachine.run_command(cmd)
            if exit_code != 0: console_out("\tFAIL")
            linking_is_required = True
    if linking_is_required:
        console_out("Create symlinks for backward compatibility")
        for folder in default_storage_folders:
            from_ = str(external_storage_root) + os.sep + str(folder)
            to_ = str(default_storage_root) + os.sep + str(folder)
            cmd = "ln -sf {} {}".format(from_, to_)
            exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    return True

def create_base_strucure(storage_root_path, path_list):
    cmd="mkdir -p "
    for path in path_list:
        full_cmd = cmd + path
        if not os.path.exists(path) and not os.path.islink(path):
            console_out("CMD: " + str(full_cmd))
            exit_code, stdout, stderr = LocalMachine.run_command(full_cmd)
            if exit_code == 0:
                console_out("\tCREATE DIR DONE")
            else:
                console_out("\tCREATE DIR FAIL" + str(stderr))
        else:
            console_out("Already exists: " + str(path))

    for index, path in enumerate(path_list):
        if get_user_and_group(path)[1] != str(storage_folders_groups[index]):
            cmd_grp = "sudo chgrp " + str(storage_folders_groups[index]) +  " " + str(path)
            console_out("CMD: " + str(cmd_grp))
            exit_code, stdout, stderr = LocalMachine.run_command(cmd_grp)
            if exit_code == 0:
                console_out("\tSET GROUP DONE")
            else:
                console_out("\tSET GROUP FAIL" + str(stderr))

def get_user_and_group(path):
    stat_info = os.stat(path)
    uid = stat_info.st_uid
    gid = stat_info.st_gid

    user = pwd.getpwuid(uid)[0]
    try:
        group = grp.getgrgid(gid)[0]
    except Exception as e:
        console_out("Warning!!! " + str(e))
        group = "None"
    return user, group

def get_storage_structure_folders(set_extarnal_storage, external_storage_label):
    global default_storage_root
    storage_root_path, path_list = get_storage_root_and_base_path_list(set_extarnal_storage, external_storage_label)
    if set_extarnal_storage:
        if not BlockDeviceHandler.device_is_mounted(storage_root_path):
            return "External device is not available: " + str(storage_root_path)
    create_source_file_for_bash_scripts(path_list)
    text = "Storage structure folders:"
    text += "\n(default internal storage root: " + default_storage_root + ")"
    for path in path_list:
        text += "\n" + Colors.YELLOW + path + Colors.NC + "\tgroup: " + get_user_and_group(path)[1]
        cmd = "tree -L 2 " + str(path)
        exit_code, stdout, stderr = LocalMachine.run_command(cmd)
        if exit_code == 0:
            text += stdout
    console_out(text)
    return text

# external main function
def create_storage_stucrure(set_extarnal_storage, external_storage_label):
    console_out("CREATE STORAGE STUCTURE FOR RPITOOLS")
    storage_root_path, path_list = get_storage_root_and_base_path_list(set_extarnal_storage, external_storage_label)
    console_out("Set external storage: " + str(set_extarnal_storage))
    console_out("Storage root: " + str(storage_root_path))
    console_out("Storage path list: " + str(path_list))

    create_base_strucure(storage_root_path, path_list)
    create_source_file_for_bash_scripts(path_list)

def create_source_file_for_bash_scripts(path_list):
    global default_storage_root
    source_path = pathname + os.sep + "../../../cache/storage_path_structure"
    text = "# storage structure"
    for path in path_list:
        if "user" in path.lower():
            var_name = "USERSPACE="
        elif "shared" in path.lower():
            var_name = "SHAREDSPACE="
        elif "other" in path.lower():
            var_name = "OTHERSPACE="
        else:
            var_name = "UNKNOWN="
        text +=  "\n" + var_name + path
    try:
        with open(source_path, 'w') as f:
            f.write(text)
    except Exception as e:
        console_out("Create storage stucture source file failed: " + str(e))
