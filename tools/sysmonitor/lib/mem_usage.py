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

def get_mem_usage():
    mem_total = LocalMachine.run_command_safe("sudo cat /proc/meminfo | grep 'MemTotal' | tr -dc '0-9'")
    mem_available = LocalMachine.run_command_safe("sudo cat /proc/meminfo | grep 'MemAvailable' | tr -dc '0-9'")
    mem_free = LocalMachine.run_command_safe("sudo cat /proc/meminfo | grep 'MemFree' | tr -dc '0-9'")

    available_percent = (float(int(mem_total) - int(mem_available)) / float(mem_total)) * 100
    available_percent = '%.1f' % available_percent

    free_percent = (float(int(mem_total) - int(mem_free)) / float(mem_total)) * 100
    free_percent = '%.1f' % free_percent
    return float(available_percent), float(free_percent), mem_total, mem_available, mem_free

def create_printout(separator="|", char_width=80, export=None):
    text = GeneralElements.header_bar(" MEM USAGE ", char_width, separator, color_name=Colors.LIGHT_CYAN)
    mem_usage_av_percent, mem_usage_free_percent, total, available, free = get_mem_usage()

    text += " Total: {} Mb Available: {} Mb Free: {} Mb\n".format(int(total)/1024, int(available)/1024, int(free)/1024)
    text += GeneralElements.indicator_bar(mem_usage_av_percent, dim="%", pre_text="MEM AV. ", char_width=char_width)
    text += GeneralElements.indicator_bar(mem_usage_free_percent, dim="%", pre_text="MEM FREE", char_width=char_width)
    if export is not None and export:
        text += set_memdict_memory_health(mem_usage_av_percent)
    return text

def set_memdict_memory_health(percent_av, av_percent_alarm=None):
    if av_percent_alarm is None:
        av_percent_alarm = ConfigHandlerInterface.get_HALARM_value_by_key("memory_min_free_percent")
    percent = int(percent_av)
    state = "OK"
    info_field = ""
    if av_percent_alarm <= percent_av:
        state = "ALARM"
        info_field = "== MEM ALARM: {}%, actual: {}%".format(av_percent_alarm, percent_av)

    try:
        MemDictHandler.set_value_MemDict(key="memory", value=state)
        if info_field != "":
            existing_text = MemDictHandler.get_value_metadata_info()
            MemDictHandler.set_value_metadata_info(str(info_field))
    except Exception as e:
        print("Write MEM to memdict failed: " + str(e))

    if info_field != "":
        return " HEALTH: {}{}{}\n INFO:\n{}".format(Colors.RED, str(state).upper(), Colors.NC, info_field)
    else:
        return " HEALTH: {}{}{} limit: {}%".format(Colors.GREEN, str(state).upper(), Colors.NC, av_percent_alarm)

def main(export=True):
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1], export=export)

if __name__ == "__main__":
    print(main())
