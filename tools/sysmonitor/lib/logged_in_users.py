import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors

def get_logged_in_users():
    data_tmp = LocalMachine.run_command_safe("ps -ef | grep [s]shd | grep -v ^root")
    data_list = data_tmp.split("\n")
    data = ""
    for index, line in enumerate(data_list):
        data += " " + line + "\n"
    return data

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" LOGGED-IN USERS ", char_width, separator, color_name=Colors.LIGHT_BLUE)
    text +=  get_logged_in_users()
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
