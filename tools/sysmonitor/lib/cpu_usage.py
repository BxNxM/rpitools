import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors

def get_cpu_usage():
    data = LocalMachine.run_command_safe("/home/$USER/rpitools/tools/proc_stat.sh")
    data = data[6:-6]
    return int(data)

def get_top_processes(topx=3):
    output = ""
    cmd = "ps aux | head -n 1; ps aux --sort -rss | sort -nrk 3,3 | head -n " + str(topx)
    data = LocalMachine.run_command_safe(cmd)
    data_list = data.split("\n")
    for line in data_list:
        output += " " + line + "\n"
    return output

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" CPU USAGE ", char_width, separator, color_name=Colors.LIGHT_PURPLE)
    cpu_usage = get_cpu_usage()

    text += GeneralElements.indicator_bar(cpu_usage, dim="%", pre_text="CPU", char_width=char_width, col_scale=[0.75, 0.90])
    text += get_top_processes()

    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
