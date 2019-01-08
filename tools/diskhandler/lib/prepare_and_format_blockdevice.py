import BlockDeviceHandler
import json
import LocalMachine
import os

def parse_config_file_from_disk(path, confname="diskconf.json"):
    json_path = str(path) + "/" + str(confname)
    if not os.path.exists(json_path):
        print("\tPath not exists: " + str(json_path))
        return None
    with open(json_path, "r") as f:
        data = json.load(f)
    print("config: " + str(confname) + " => " + str(data))
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

def format_device_based_on_config_file(dev, premount_path):
    print("Format device")
    diskconf_path = premount_path
    data = parse_config_file_from_disk(diskconf_path)
    if data is not None:
        if data['is_formatted'] != "True":
            print("\tSave disk config file before formatting")
            save_diskconf_file(diskconf_path)
            print("\tUnmount device before formatting")
            BlockDeviceHandler.unmount_device(dev)
            print("\tFormat device")
            BlockDeviceHandler.format_ex4(dev, data['label'])
            print("\tMount formatted device")
            mount_point = BlockDeviceHandler.mount_device(dev)
            print("\tSave back the the config file with the new state")
            write_state_config_file_from_disk(mount_point, data)
        else:
            print("\tDisk already formatted: {}:{}".format(dev, premount_path))
    mount_point = BlockDeviceHandler.mount_device(dev)

def prepare_block_device():
    if BlockDeviceHandler.is_any_device_avaible():
        print("Block device exists")
        devices = BlockDeviceHandler.list_connected_devices()
        for dev in devices:
            premount_path = BlockDeviceHandler.premount_device(dev)
            format_device_based_on_config_file(dev, premount_path)
        BlockDeviceHandler.unmount_all_premounted_devices()

if __name__ == "__main__":
    prepare_block_device()
    #BlockDeviceHandler.unmount_all_devices(del_mount_point=True)
