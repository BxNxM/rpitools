import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors
import MemDictHandler

def get_cpu_temp():
    data = LocalMachine.run_command_safe("/opt/vc/bin/vcgencmd measure_temp")
    data = data[5:-2]
    return float(data)

def get_gpu_temp():
    data = LocalMachine.run_command_safe("cat /sys/class/thermal/thermal_zone0/temp")
    data = float(data) / 1000
    data = '%.1f' % data
    return float(data)

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" TEMPERATURE ", char_width, separator, color_name=Colors.LIGHT_GRAY)
    cpu_temp = get_cpu_temp()
    gpu_temp = get_gpu_temp()

    text += GeneralElements.indicator_bar(cpu_temp, dim="'C", pre_text="CPU", char_width=char_width)
    text += GeneralElements.indicator_bar(gpu_temp, dim="'C", pre_text="GPU", char_width=char_width)
    text += set_memdict_temp_health(cpu_temp)
    return text

def set_memdict_temp_health(temp, temp_alarm_at_celsius=65):
    temp = int(temp)
    state = "OK"
    info_field = ""
    if temp >= temp_alarm_at_celsius:
        state = "ALARM"
        info_field = "== HEAT ALARM: {}'C, actual: {}'C".format(temp_alarm_at_celsius, temp)

    try:
        MemDictHandler.set_value_MemDict(key="temp", value=state)
        if info_field != "":
            existing_text = MemDictHandler.get_value_metadata_info()
            MemDictHandler.set_value_metadata_info(str(info_field))
    except Exception as e:
        print("Write temp to memdict failed: " + str(e))

    if info_field != "":
        return " HEALTH: {}{}{}\n INFO:\n{}".format(Colors.RED, str(state).upper(), Colors.NC, info_field)
    else:
        return " HEALTH: {}{}{}".format(Colors.GREEN, str(state).upper(), Colors.NC)

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())

