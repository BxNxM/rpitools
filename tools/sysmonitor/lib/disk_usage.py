import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors
import MemDictHandler

def get_disk_usage():
    device_is_connected = LocalMachine.run_command_safe("echo /dev/sd*")
    if "/dev/sd*" not in device_is_connected:
        data_tmp = LocalMachine.run_command_safe("df -h / /dev/sd* | grep -v devtmpfs")
    else:
        data_tmp = LocalMachine.run_command_safe("df -h /")
    data_list = data_tmp.split("\n")
    data = ""
    for index, line in enumerate(data_list):
        data += " " + line + "\n"
    return data

def __check_disk_size_health(data, general_max_percentage):
    info_field = ""
    disk_state = 0
    disk_state_result = "unknown"
    vol_info_dict = {}
    name_index = None
    usage_index = None
    data_list = data.split("\n")
    for vol in data_list:
        vol_data_list = vol.split()
        for index, vol_data in enumerate(vol_data_list):
            if "Mounted" in vol_data and name_index is None:
                name_index = index
            if "Use%" in vol_data and usage_index is None:
                usage_index = index
        try:
            key = vol_data_list[name_index]
            value =  vol_data_list[usage_index]
            if key != "Mounted":
                vol_info_dict[key] = value
        except:
            pass

    for key_disk, value_disk in vol_info_dict.items():
        if int(value_disk[:-1]) >= general_max_percentage:
            disk_state += 1
            info_field += "=== [ALARM] {} disk, use more then {}%, actual: {}!".format(key_disk, general_max_percentage, value_disk)

    if disk_state == 0:
        disk_state_result = "OK"
    else:
        disk_state_result = "ALARM"
    return disk_state_result, info_field

def disk_health_mapper(data, general_max_percentage=90):
    try:
        state, info_field = __check_disk_size_health(data, general_max_percentage)
    except Exception as e:
        print("disk_health_mapper fails: " + str(e))
        state = "unknown"
        info_field = "DISK: query fail"

    try:
        MemDictHandler.set_value_MemDict(key="disk", value=state)
        if info_field != "":
            existing_text = MemDictHandler.get_value_metadata_info()
            MemDictHandler.set_value_metadata_info(str(info_field))
    except Exception as e:
        print("Write disk to memdict failed: " + str(e))

    if info_field != "":
        return " HEALTH: {}{}{}\n INFO:\n{}".format(Colors.RED, str(state).upper(), Colors.NC, info_field)
    else:
        return " HEALTH: {}{}{}".format(Colors.GREEN, str(state).upper(), Colors.NC)

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" DISK USAGE ", char_width, separator, color_name=Colors.BROWN)
    data_tmp =  get_disk_usage()
    text += data_tmp
    text += disk_health_mapper(data_tmp)
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
