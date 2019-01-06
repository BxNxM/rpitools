#!/usr/bin/python

import LocalMachine
import os
import sys
import grp
import pwd
pathname = os.path.dirname(sys.argv[0])
default_storage_folders = ["/UserSpace", "/SharedSpace", "/OtherSpace"]
storage_folders_groups = [ "rpitools_admin", "rpitools_user", "rpitools_admin"]
default_storage_root = "/media/virtaul_storage"

def get_storage_root_and_base_path_list(set_extarnal_storage, external_storage_label):
    global default_storage_folders
    global default_storage_root
    path_list = []

    if set_extarnal_storage:
        storage_root_path = "/media/" + str(external_storage_label)
        if not os.path.exists(storage_root_path):
            print("Storage not exists! -> " + str(storage_root_path))
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
            print("Migrate storage from {} to {}".format(default_storage_root, external_storage_root))
            exit_code, stdout, stderr = LocalMachine.run_command(cmd)
            if exit_code != 0: print("\tFAIL")
            linking_is_required = True
    if linking_is_required:
        print("Create symlinks for backward compatibility")
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
            print("CMD: " + str(full_cmd))
            exit_code, stdout, stderr = LocalMachine.run_command(full_cmd)
            if exit_code == 0:
                print("\tCREATE DIR DONE")
            else:
                print("\tCREATE DIR FAIL" + str(stderr))
        else:
            print("Already exists: " + str(path))

    for index, path in enumerate(path_list):
        if get_user_and_group(path)[1] != str(storage_folders_groups[index]):
            cmd_grp = "sudo chgrp " + str(storage_folders_groups[index]) +  " " + str(path)
            print("CMD: " + str(cmd_grp))
            exit_code, stdout, stderr = LocalMachine.run_command(cmd_grp)
            if exit_code == 0:
                print("\tSET GROUP DONE")
            else:
                print("\tSET GROUP FAIL" + str(stderr))

def get_user_and_group(path):
    stat_info = os.stat(path)
    uid = stat_info.st_uid
    gid = stat_info.st_gid

    user = pwd.getpwuid(uid)[0]
    group = grp.getgrgid(gid)[0]
    return user, group

def get_storage_structure_folders(set_extarnal_storage, external_storage_label):
    storage_root_path, path_list = get_storage_root_and_base_path_list(set_extarnal_storage, external_storage_label)
    text = "Storage structure folders:"
    for path in path_list:
        text += "\n" + path + "\tgroup: " + get_user_and_group(path)[1]
    create_source_file_for_bash_scripts(path_list)
    return text

# external main function
def create_storage_stucrure(set_extarnal_storage, external_storage_label):
    storage_root_path, path_list = get_storage_root_and_base_path_list(set_extarnal_storage, external_storage_label)
    print("Set external storage: " + str(set_extarnal_storage))
    print("Storage root: " + str(storage_root_path))
    print("Storage path list: " + str(path_list))

    create_base_strucure(storage_root_path, path_list)
    create_source_file_for_bash_scripts(path_list)

def create_source_file_for_bash_scripts(path_list):
    global default_storage_root
    source_path = pathname + os.sep + "../../../cache/storage_path_structure"
    text = "# storage structure"
    for path in path_list:
        if "user" in path.lower():
            var_name = "userspace="
        elif "shared" in path.lower():
            var_name = "sharedspace="
        elif "other" in path.lower():
            var_name = "otherspace="
        else:
            var_name = "unknown="
        text +=  "\n" + var_name + path
    try:
        with open(source_path, 'w') as f:
            f.write(text)
    except Exception as e:
        print("Create storage stucture source file failed: " + str(e))
