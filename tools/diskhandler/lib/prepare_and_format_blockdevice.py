import BlockDeviceHandler
import json
import LocalMachine
import os

""" This module automaticly format the disk based on diskconf.json """

def module_print(text):
    print_text = "[ autoformat disk ] " + str(text)
    print(print_text)

def parse_config_file_from_disk(path, confname="diskconf.json"):
    json_path = str(path) + "/" + str(confname)
    if not os.path.exists(json_path):
        module_print("\tPath not exists: " + str(json_path))
        return None
    with open(json_path, "r") as f:
        data = json.load(f)
    module_print("config: " + str(confname) + " => " + str(data))
    return data

def write_state_config_file_from_disk(path, data, confname="diskconf.json"):
    json_path = str(path) + "/" + str(confname)
    with open(json_path, "w") as f:
        data['is_formatted'] = "True"
        json.dump(data, f, indent=2)

def save_diskconf_file(path, confname="diskconf.json"):
    json_path = str(path) + "/" + str(confname)
    save_path = "/tmp"
    cmd = "sudo cp {} {}".format(json_path, save_path)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    BlockDeviceHandler.check_exitcode(cmd, exitcode, stderr)

def restore_diskconf_file(path, confname="diskconf.json"):
    json_path = str(path) + "/" + str(confname)
    save_path = "/tmp/" + str(confname)
    cmd = "sudo cp {} {}".format(save_path, json_path)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    BlockDeviceHandler.check_exitcode(cmd, exitcode, stderr)
    cmd = "sudo rm -f {}".format(save_path)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd)
    BlockDeviceHandler.check_exitcode(cmd, exitcode, stderr)

def safe_format_disk_check_force_mode(json_data, dev):
    dev_data_modified = False
    # disk is not formatted
    dev_data = BlockDeviceHandler.get_device_info_data(dev)
    if json_data['label'] != dev_data['label']:
        dev_data_modified = True
    if json_data['format'] != dev_data['filesystem']:
        dev_data_modified = True

    if json_data['is_formatted'] == "False":
        if json_data['force'] == "True" and dev_data_modified is False:
            module_print("[i] [format] Block device paramaters not changed but force mode is ON")
            return True
        elif dev_data_modified is True:
            module_print("[i] [format] Requested block device parameter(s) changed - format")
            return True
        else:
            module_print("[i] [Skip format] Blockdevice format not needed - label and system not changed")
            return False
    else:
        module_print("[i] [is_formatted:True] Blockdevice already formatted.")
        return False

def format_device_based_on_config_file(dev, premount_path):
    module_print("Format device")
    diskconf_path = premount_path
    data = parse_config_file_from_disk(diskconf_path)
    if data is not None:
        if safe_format_disk_check_force_mode(data, dev):
            module_print("\tSave disk config file before formatting")
            save_diskconf_file(diskconf_path)
            module_print("\tUnmount device before formatting")
            BlockDeviceHandler.unmount_device(dev)
            module_print("\tFormat device")
            BlockDeviceHandler.format_ex4(dev, data['label'])
            module_print("\tMount formatted device")
            mount_point = BlockDeviceHandler.mount_device(dev)
            module_print("\tSave back the the config file with the new state")
            write_state_config_file_from_disk(mount_point, data)
        else:
            module_print("\tDisk already formatted: {}:{}".format(dev, premount_path))
    module_print("mount device: " + str(dev))
    mount_point = BlockDeviceHandler.mount_device(dev)

def prepare_block_device():
    if BlockDeviceHandler.is_any_device_avaible():
        module_print("Block device exists")
        devices = BlockDeviceHandler.list_connected_devices()
        for dev in devices:
            premount_path = BlockDeviceHandler.premount_device(dev)
            format_device_based_on_config_file(dev, premount_path)
        BlockDeviceHandler.unmount_all_premounted_devices()

if __name__ == "__main__":
    prepare_block_device()
    #BlockDeviceHandler.unmount_all_devices(del_mount_point=True)
