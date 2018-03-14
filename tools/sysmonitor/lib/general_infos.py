import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors

def get_pi_version():
    data = LocalMachine.run_command_safe("sudo uname -a")
    return data

def get_cpu_freq():
    data = LocalMachine.run_command_safe("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
    return data

def get_internal_ip():
    data = LocalMachine.run_command_safe("hostname -I")
    return data

def get_external_ip():
    data = LocalMachine.run_command_safe("curl http://ipecho.net/plain 2>/dev/null")
    return data

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" GENERAL ", char_width, separator, color_name=Colors.DARK_GRAY)
    version = get_pi_version()
    int_ip = get_internal_ip()
    ext_ip = get_external_ip()
    cpu_freq = get_cpu_freq()

    text += " Internal IP address:\t{}\n".format(int_ip)
    text += " External IP address:\t{}\n".format(ext_ip)
    text += " CPU actual frequency:\t{} MHz\n".format(int(cpu_freq)/1000)
    text += " {}\n".format(version)
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
