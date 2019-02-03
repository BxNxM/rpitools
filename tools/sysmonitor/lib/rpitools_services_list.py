import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors

def get_rpitools_services(color=Colors.CYAN):
    services=["oled_gui_core", "dropbox_halpage", "auto_restart_transmission", "rpitools_logrotate", "memDictCore", "rgb_led_controller", "temp_controll_fan"]
    data = color + " RPITOOLS SERVICES:\n" + Colors.NC
    for service in services:
        is_active = LocalMachine.run_command("systemctl is-active " + str(service))[1]
        is_enabled = LocalMachine.run_command("systemctl is-enabled " + str(service))[1]
        data += "\t" + color + str(service) + Colors.NC + " active status: " + str(is_active) + "\n"

        data += "\t" + str(service) + " enabled status: " + str(is_enabled) + "\n"
    services=["apache2", "transmission-daemon", "motion", "smbd", "minidlna", "ssh", "nfs-kernel-server", "glances", "cron"]
    data += color + " LINUX SERVICES:\n" + Colors.NC
    for service in services:
        is_active = LocalMachine.run_command("systemctl is-active " + str(service))[1]
        is_enabled = LocalMachine.run_command("systemctl is-enabled " + str(service))[1]
        data += "\t" + color + str(service) + Colors.NC + " active status: " + str(is_active) + "\n"
        data += "\t" + str(service) + " enabled status: " + str(is_enabled) + "\n"
    return data

def create_printout(separator="|", char_width=80, color=Colors.CYAN):
    text = GeneralElements.header_bar(" SERVICES ", char_width, separator, color_name=color)
    text += get_rpitools_services()
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
