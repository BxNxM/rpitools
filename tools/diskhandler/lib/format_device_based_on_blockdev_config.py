import BlockDeviceHandler
import mount_connected_disks
import json

def parse_config_file_from_disk(path, confname="diskconf.json"):
    json_path = str(path) + "/" + str(confname)
    with open(json_path, "r") as f:
        data = json.load(f)
    print(data)

def format_device_based_on_config_file():
    print("Format device")
    parse_config_file_from_disk("./")

def prepare_block_device():
    if mount_connected_disks.is_any_device_avaible():
        print("Block device exists")
        devices = mount_connected_disks.list_connected_devices()
        for dev in devices:
            BlockDeviceHandler.premount_device(dev)
            format_device_based_on_config_file()
        BlockDeviceHandler.unmount_all_premounted_devices()

if __name__ == "__main__":
    prepare_block_device()
