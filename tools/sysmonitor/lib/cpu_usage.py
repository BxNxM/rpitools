import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters

def get_cpu_usage():
    data = LocalMachine.run_command_safe("/home/$USER/rpitools/tools/proc_stat.sh")
    data = data[6:-6]
    return int(data)

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" CPU USAGE ", char_width, separator)
    cpu_usage = get_cpu_usage()

    text += GeneralElements.indicator_bar(cpu_usage, dim="%", pre_text="CPU", char_width=char_width, col_scale=[0.75, 0.90])
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
