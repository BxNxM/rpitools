import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors

def get_date_time():
    data = LocalMachine.run_command_safe("date")
    return data

def get_username():
    data = LocalMachine.run_command_safe("echo $USER")
    return data

def create_printout(separator="|", char_width=80, color=Colors.BLUE):
    date_time = " {} ".format(get_date_time())
    username = get_username()
    text = GeneralElements.header_bar(date_time, char_width, separator, color_name=color)
    text += GeneralElements.header_bar(" RPItools monitor ", char_width, separator, color_name=color)
    text += GeneralElements.header_bar(" Hi, " + username + "! Have a GOO:D time! ", char_width, separator, color_name=color)
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
