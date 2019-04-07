import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors
import MemDictHandler
health_error_code = 0
health_all_monitored = 0
rpitools_services = ["oled_gui_core", "dropbox_halpage", "auto_restart_transmission", "rpitools_logrotate", "memDictCore", "rgb_led_controller", "temp_controll_fan", "hAlarm"]
linux_services = ["apache2", "transmission-daemon", "motion", "smbd", "minidlna", "ssh", "nfs-kernel-server", "glances", "cron", "networking"]
health_sub_states={"rpitools_services_si": [0, ""], "linux_services_si": [0, ""], "processes_si": [0, ""]}

def get_rpitools_services(color=Colors.CYAN):
    global rpitools_services, linux_services
    services = rpitools_services
    data = color + " RPITOOLS SERVICES:\n" + Colors.NC
    for service in services:
        is_active = LocalMachine.run_command("systemctl is-active " + str(service))[1]
        is_enabled = LocalMachine.run_command("systemctl is-enabled " + str(service))[1]
        is_active, is_enabled = service_state_coloring(isactive=is_active, isenabled=is_enabled, service_name=service)
        data += "\t" + color + str(service) + Colors.NC + " active status: " + str(is_active) + "\n"

        data += "\t" + str(service) + " enabled status: " + str(is_enabled) + "\n"
    services = linux_services
    data += color + " LINUX SERVICES:\n" + Colors.NC
    for service in services:
        is_active = LocalMachine.run_command("systemctl is-active " + str(service))[1]
        is_enabled = LocalMachine.run_command("systemctl is-enabled " + str(service))[1]
        is_active, is_enabled = service_state_coloring(isactive=is_active, isenabled=is_enabled, service_name=service)
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
        process_state, is_enabled = service_state_coloring(isactive=process_state, service_name=process)
        data += "\t" + color + str(process) + Colors.NC + " state: " + str(process_state) + "\n"
    return data

def service_state_coloring(isactive, isenabled=None, service_name=""):
    global health_error_code, health_all_monitored
    health_all_monitored += 1
    if isenabled is not None:
        if isenabled == "enabled":
            if isactive == "active":
                is_active = Colors.GREEN + isactive + Colors.NC
            else:
                is_active = Colors.RED + isactive + Colors.NC
                health_error_code += 1
                if service_name in rpitools_services:
                    health_sub_states["rpitools_services_si"][0] += 1
                    health_sub_states["rpitools_services_si"][1] += str(service_name).replace("-", "") + ": ERROR =="
                elif service_name in linux_services:
                    health_sub_states["linux_services_si"][0] += 1
                    health_sub_states["linux_services_si"][1] += str(service_name).replace("-", "") + ": ERROR =="
        elif isenabled == "disabled":
            if isactive == "active":
                is_active = Colors.YELLOW + isactive + Colors.NC
                health_error_code += 0.1
                if service_name in rpitools_logrotate:
                    health_sub_states["rpitools_services_si"][0] += 0.1
                    health_sub_states["rpitools_services_si"][1] += str(service_name).replace("-", "") + ": WARNING =="
                elif service_name in linux_services:
                    health_sub_states["linux_services_si"][0] += 0.1
                    health_sub_states["linux_services_si"][1] += str(service_name).replace("-", "") + ": WARNING =="
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

def process_state_coloring(status, title, color=Colors.CYAN):
    global health_error_code, health_all_monitored
    health_all_monitored += 1
    if "ok" in status:
        autosync_status = Colors.GREEN + str(status) + Colors.NC
    elif "warning" in status:
        autosync_status = Colors.YELLOW + str(status) + Colors.NC
        health_error_code += 0.1
        health_sub_states["processes_si"][0] += 0.1
        health_sub_states["processes_si"][1] += str(title) + " process WARNING =="
    elif "fail" in status:
        autosync_status = Colors.RED + str(status) + Colors.NC
        health_error_code += 1
        health_sub_states["processes_si"][0] += 1
        health_sub_states["processes_si"][1] += str(title) + " process ERROR =="
    elif "unknown" in status:
        autosync_status = Colors.YELLOW + str(status) + Colors.NC
        health_error_code += 0.1
        health_sub_states["processes_si"][1] += str(title) + " process UNKNOWN =="
    else:
        autosync_status = "inactive"
    return color + "\t" + str(title) + " state: " + Colors.NC + str(autosync_status) + "\n"

def get_autosync_status(color=Colors.CYAN):
    autosync_status = LocalMachine.run_command("cat ~/rpitools/tools/autosync/.status")[1]
    return process_state_coloring(autosync_status, "autosync")

def get_backuphandler_status(color=Colors.CYAN):
    backuphandler_status = LocalMachine.run_command("cat ~/rpitools/tools/backuphandler/.status")[1]
    return process_state_coloring(backuphandler_status, "backuphandler")

def calculate_health_multipayer():
    global health_error_code, health_all_monitored
    health_index = 100 - round((float(health_error_code) / health_all_monitored) * 100, 1)
    text = " {}OVERALL HEALTH{} [{}%]:\n\t:) {}0{}{}...{}{}{} :( exit code: {}".format(Colors.CYAN, Colors.NC, health_index, Colors.GREEN, \
            Colors.NC, Colors.YELLOW, Colors.RED, health_all_monitored, Colors.NC, health_error_code)
    return text

def system_health_data_handler(rpitools_services_si=None, linux_services_si=None, processes_si=None):
    if rpitools_services_si is not None:
        state = rpitools_services_si[0]
        info_text = rpitools_services_si[1]
        try:
            MemDictHandler.set_value_MemDict(key="rpitools_services", value=state)
            if info_text != "":
                existing_text = MemDictHandler.get_value_metadata_info()
                MemDictHandler.set_value_metadata_info(str(existing_text) + str(info_text))
        except Exception as e:
            print("Write rpitools_services to memdict failed: " + str(e))

    if linux_services_si is not None:
        state = linux_services_si[0]
        info_text = linux_services_si[1]
        try:
            MemDictHandler.set_value_MemDict(key="linux_services", value=state)
            if info_text != "":
                existing_text = MemDictHandler.get_value_metadata_info()
                MemDictHandler.set_value_metadata_info(str(existing_text) + str(info_text))
        except Exception as e:
            print("Write linux_services to memdict failed: " + str(e))

    if processes_si is not None:
        state = processes_si[0]
        info_text = processes_si[1]
        try:
            MemDictHandler.set_value_MemDict(key="processes", value=state)
            if info_text != "":
                existing_text = MemDictHandler.get_value_metadata_info()
                MemDictHandler.set_value_metadata_info(str(existing_text) + str(info_text))
        except Exception as e:
            print("Write processes to memdict failed: " + str(e))

def update_system_health_data_with_services_state():
    global health_sub_states
    if health_sub_states["rpitools_services_si"][0] == 0:
        health_sub_states["rpitools_services_si"][0] = "OK"
    else:
        health_sub_states["rpitools_services_si"][0] = "ALARM"

    if health_sub_states["linux_services_si"][0] == 0:
        health_sub_states["linux_services_si"][0] = "OK"
    else:
        health_sub_states["linux_services_si"][0] = "ALARM"

    if health_sub_states["processes_si"][0] == 0:
        health_sub_states["processes_si"][0] = "OK"
    else:
        health_sub_states["processes_si"][0] = "ALARM"
    system_health_data_handler(health_sub_states["rpitools_services_si"], health_sub_states["linux_services_si"], health_sub_states["processes_si"])

def create_printout(separator="|", char_width=80, color=Colors.CYAN):
    global health_sub_states
    text = GeneralElements.header_bar(" SERVICES ", char_width, separator, color_name=color)
    text += get_rpitools_services()
    text += get_other_monitored_processes()
    text += get_autosync_status()
    text += get_backuphandler_status()
    text += calculate_health_multipayer()
    update_system_health_data_with_services_state()
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
