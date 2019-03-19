import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors
health_error_code = 0
health_all_monitored = 0

def get_rpitools_services(color=Colors.CYAN):
    services=["oled_gui_core", "dropbox_halpage", "auto_restart_transmission", "rpitools_logrotate", "memDictCore", "rgb_led_controller", "temp_controll_fan"]
    data = color + " RPITOOLS SERVICES:\n" + Colors.NC
    for service in services:
        is_active = LocalMachine.run_command("systemctl is-active " + str(service))[1]
        is_enabled = LocalMachine.run_command("systemctl is-enabled " + str(service))[1]
        is_active, is_enabled = state_coloring(isactive=is_active, isenabled=is_enabled)
        data += "\t" + color + str(service) + Colors.NC + " active status: " + str(is_active) + "\n"

        data += "\t" + str(service) + " enabled status: " + str(is_enabled) + "\n"
    services=["apache2", "transmission-daemon", "motion", "smbd", "minidlna", "ssh", "nfs-kernel-server", "glances", "cron", "networking"]
    data += color + " LINUX SERVICES:\n" + Colors.NC
    for service in services:
        is_active = LocalMachine.run_command("systemctl is-active " + str(service))[1]
        is_enabled = LocalMachine.run_command("systemctl is-enabled " + str(service))[1]
        is_active, is_enabled = state_coloring(isactive=is_active, isenabled=is_enabled)
        data += "\t" + color + str(service) + Colors.NC + " active status: " + str(is_active) + "\n"
        data += "\t" + str(service) + " enabled status: " + str(is_enabled) + "\n"
    return data

def get_other_monitored_processes(color=Colors.CYAN):
    process_name_list=["Xorg", "vncserver", "kodi"]
    data = color + " MONITORED PROCESSES:\n" + Colors.NC
    for process in process_name_list:
        exitcode, process_state, stderr = LocalMachine.run_command("ps aux | grep -v grep | grep '" + str(process) + "'")
        if process_state == "":
            process_state = "inactive"
        else:
            process_state = "active"
        process_state, is_enabled = state_coloring(isactive=process_state)
        data += "\t" + color + str(process) + Colors.NC + " state: " + str(process_state) + "\n"
    return data

def state_coloring(isactive, isenabled=None):
    global health_error_code, health_all_monitored
    health_all_monitored += 1
    if isenabled is not None:
        if isenabled == "enabled":
            if isactive == "active":
                is_active = Colors.GREEN + isactive + Colors.NC
            else:
                is_active = Colors.RED + isactive + Colors.NC
                health_error_code += 1
        elif isenabled == "disabled":
            if isactive == "active":
                is_active = Colors.YELLOW + isactive + Colors.NC
                health_error_code += 0.1
            else:
                is_active = Colors.GREEN + isactive + Colors.NC
        else:
            is_active = isenabled
    else:
        if isactive == "active":
            is_active = Colors.GREEN + isactive + Colors.NC
        else:
            is_active = isactive
    return is_active, isenabled

def get_autosync_status(color=Colors.CYAN):
    autosync_status = LocalMachine.run_command("cat ~/rpitools/tools/autosync/.status")[1]
    if "ok" in autosync_status:
        autosync_status = Colors.GREEN + str(autosync_status) + Colors.NC
    elif "warning" in autosync_status:
        autosync_status = Colors.YELLOW + str(autosync_status) + Colors.NC
    elif "fail" in autosync_status:
        autosync_status = Colors.RED + str(autosync_status) + Colors.NC
    elif "unknown" in autosync_status:
        autosync_status = Colors.YELLOW + str(autosync_status) + Colors.NC
    else:
        autosync_status = "inactive"
    return color + "\tautosync state: " + Colors.NC + str(autosync_status) + "\n"

def calculate_health_multipayer():
    global health_error_code, health_all_monitored
    health_index = 100 - round((float(health_error_code) / health_all_monitored) * 100, 1)
    text = " {}OVERALL HEALTH{} [{}%]:\n\t:) {}0{}{}...{}{}{} :( exit code: {}".format(Colors.CYAN, Colors.NC, health_index, Colors.GREEN, \
            Colors.NC, Colors.YELLOW, Colors.RED, health_all_monitored, Colors.NC, health_error_code)
    return text

def create_printout(separator="|", char_width=80, color=Colors.CYAN):
    text = GeneralElements.header_bar(" SERVICES ", char_width, separator, color_name=color)
    text += get_rpitools_services()
    text += get_other_monitored_processes()
    text += get_autosync_status()
    text += calculate_health_multipayer()
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
