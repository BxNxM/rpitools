import sys
sys.path.append("api")
import LocalMachine
import GeneralElements
import ConsoleParameters

def get_logged_in_users():
    data_tmp = LocalMachine.run_command_safe("ps -ef | grep [s]shd | grep -v ^root")
    data_list = data_tmp.split("\n")
    data = ""
    for index, line in enumerate(data_list):
        data += " " + line
        if len(data_list) - 1 != index:
            data += "\n"
    return data

def create_printout(separator="#", char_width=80):
    text = GeneralElements.header_bar(" LOGGED-IN USERS ", char_width, separator)
    text +=  get_logged_in_users()
    return text

if __name__ == "__main__":
    rowcol = ConsoleParameters.console_rows_columns()
    print(create_printout(char_width=rowcol[1]))
