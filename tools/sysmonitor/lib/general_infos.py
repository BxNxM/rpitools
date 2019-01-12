import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
sys.path.append(os.path.join(myfolder, "../../../autodeployment/lib"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors
import ConfigHandler

def get_rpitools_version():
    cfg = ConfigHandler.init(validate_print=False)
    data = cfg.get("GENERAL", "rpitools_version")
    return data

def get_pi_version():
    data = LocalMachine.run_command_safe("sudo uname -a")
    return data

def get_cpu_freq():
    data = LocalMachine.run_command_safe("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
    return data

def get_internal_ip():
    data = LocalMachine.run_command_safe("hostname -I")
    data_list = data.split(" ")
    ip_printout = ""
    for index, ip in enumerate(data_list):
        ip_printout += "IP[{}]: {} ".format(index, ip)
    return ip_printout

def get_external_ip():
    data = LocalMachine.run_command_safe("curl http://ipecho.net/plain 2>/dev/null")
    return data

def get_mac_addresses():
    output = ""
    devices = LocalMachine.run_command_safe("ls -1 /sys/class/net")
    devices_list = devices.split("\n")
    for index, device in enumerate(devices_list):
        if device != "lo":
            cmd = "ifconfig " + device + " | grep 'HWaddr'"
            mac_line = LocalMachine.run_command_safe(cmd)
            if str(mac_line) != "" and mac_line is not None:
                output += " \t" + device + "\t\t" + str(mac_line)[-17:]
                if index < len(devices_list) - 1:
                    output += "\n"
    return output

def get_dedicated_gpu_mem():
    # gpu memory size
    gpu_memory = LocalMachine.run_command_safe("vcgencmd get_mem gpu")
    gpu_memory = gpu_memory[4:-1]
    return gpu_memory

def get_swap_memory_size():
    # sap memory size
    swap_size = LocalMachine.run_command_safe("cat /etc/dphys-swapfile | grep CONF_SWAPSIZE")
    swap_size = swap_size[14:]
    return swap_size

def get_device_version():
    # sap memory size
    dev_version = LocalMachine.run_command_safe("cat /sys/firmware/devicetree/base/model")
    return dev_version.rstrip()

def create_printout(separator="|", char_width=80):
    text = GeneralElements.header_bar(" GENERAL ", char_width, separator, color_name=Colors.DARK_GRAY)
    version = get_pi_version()
    int_ip = get_internal_ip()
    ext_ip = get_external_ip()
    cpu_freq = get_cpu_freq()

    text += " Internal IP address:\t{}\n".format(int_ip)
    text += " External IP address:\t{}\n".format(ext_ip)
    text += " CPU actual frequency:\t{} MHz\n".format(int(cpu_freq)/1000)
    text += " GPU memory size:\t{} Mb\n".format(get_dedicated_gpu_mem())
    text += " SWAP memory size:\t{} Mb\n".format(get_swap_memory_size())
    text += " DEVICE version:\t{}\n".format(get_device_version())
    text += " RPITOOLS version:\t{}\n".format(get_rpitools_version())
    text += " MAC addresses:\n{}\n".format(get_mac_addresses())
    text += " {}".format(version)
    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
