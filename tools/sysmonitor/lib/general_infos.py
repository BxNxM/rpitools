import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(myfolder, "api"))
import LocalMachine
import GeneralElements
import ConsoleParameters
from Colors import Colors

def rpienv_source():
    import subprocess
    if not os.path.exists(str(myfolder) + '/.rpienv'):
        print("[ ENV ERROR ] " + str(myfolder) + "/.rpienv path not exits!")
        sys.exit(1)
    command = ['bash', '-c', 'source ' + str(myfolder) + '/.rpienv -s && env']
    proc = subprocess.Popen(command, stdout = subprocess.PIPE)
    for line in proc.stdout:
        if type(line) is bytes:
            line = line.decode("utf-8")
        try:
            name = line.partition("=")[0]
            value = line.partition("=")[2]
            if type(value) is unicode:
                value = value.encode('ascii','ignore')
            value = value.rstrip()
            os.environ[name] = value
        except Exception as e:
            if "name 'unicode' is not defined" != str(e):
                print(e)
    proc.communicate()
rpienv_source()

try:
    confhandler_path = os.path.join(os.path.dirname(os.environ['CONFIGHANDLERPY']))
    sys.path.append(confhandler_path)
    import ConfigHandler
except Exception as e:
    print("ConfigHandler import error: " + str(e))
    ConfigHandler = None

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
            mac_line = LocalMachine.run_command_safe(cmd, check_exitcode=False)
            substring_index = -17
            if mac_line == "":
                cmd = "ifconfig " + device + " | grep 'ether'"
                mac_line = LocalMachine.run_command_safe(cmd, check_exitcode=False)
                substring_index = 13
            if str(mac_line) != "" and mac_line is not None:
                output += " \t" + device + "\t\t" + str(mac_line)[substring_index:]
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

def ip_default_route():
    # get ip route command output and hughlight device
    formatted_ip_route = ""
    color = ""
    highlighted_word = ""

    ip_route = LocalMachine.run_command_safe("ip route")
    ip_route_lines = ip_route.split("\n")
    for line in ip_route_lines:
        formatted_ip_route += "\t\t\t"
        for index, word in enumerate(line.split(" ")):
            if word == "dev":
                highlighted_word = line.split(" ")[index + 1]
                color = Colors.DARK_GRAY
            if highlighted_word != ""  and highlighted_word == word:
                color = Colors.DARK_GRAY
                highlighted_word = ""
            else:
                color = ""
            formatted_ip_route += "{}{}{} ".format(color, word, Colors.NC)
        formatted_ip_route += "\n"
    return formatted_ip_route

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
    text += " DEFAULT ROUTE:\n{}".format(ip_default_route())
    text += " {}".format(version)

    return text

def main():
    rowcol = ConsoleParameters.console_rows_columns()
    return create_printout(char_width=rowcol[1])

if __name__ == "__main__":
    print(main())
