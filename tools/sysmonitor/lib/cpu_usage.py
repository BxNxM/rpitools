import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors
import MemDictHandler
import ConfigHandlerInterface

def get_cpu_usage():
    data = LocalMachine.run_command_safe("/home/$USER/rpitools/tools/proc_stat.sh")
    data = data[6:-6]
    return int(data)

def get_top_processes(char_width, topx=3):
    output = ""
    cmd = "ps aux | head -n 1; ps aux --sort -rss | sort -nrk 3,3 | head -n " + str(topx)
    data = LocalMachine.run_command_safe(cmd)
    data_list = data.split("\n")
    for line in data_list:
        output += " " + line[0:char_width] + "\n"
    return output

def create_printout(separator="|", char_width=80, export=None):
    text = GeneralElements.header_bar(" CPU USAGE ", char_width, separator, color_name=Colors.LIGHT_PURPLE)
    cpu_usage = get_cpu_usage()

    text += GeneralElements.indicator_bar(cpu_usage, dim="%", pre_text="CPU", char_width=char_width, col_scale=[0.75, 0.90])
    text += get_top_processes(char_width)
    if export is not None and export:
        text += set_memdict_cpu_health(cpu_usage)
    return text

def set_memdict_cpu_health(percent, percent_alarm=None):
    if percent_alarm is None:
        percent_alarm = ConfigHandlerInterface.get_HALARM_value_by_key("cpu_max_usage_percent")
    percent = int(percent)
    state = "OK"
    info_field = ""
    if percent >= percent_alarm:
        state = "ALARM"
        info_field = "== CPU ALARM: {}%, actual: {}%".format(percent_alarm, percent)

    try:
        MemDictHandler.set_value_MemDict(key="cpu", value=state)
        if info_field != "":
            existing_text = MemDictHandler.get_value_metadata_info()
            MemDictHandler.set_value_metadata_info(str(info_field))
    except Exception as e:
        print("Write CPU to memdict failed: " + str(e))

    if info_field != "":
        return " HEALTH: {}{}{}\n INFO:\n{}".format(Colors.RED, str(state).upper(), Colors.NC, info_field)
    else:
        return " HEALTH: {}{}{} limit: {}%".format(Colors.GREEN, str(state).upper(), Colors.NC, percent_alarm)

def main(export=True):
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1], export=export)

if __name__ == "__main__":
    print(main())
