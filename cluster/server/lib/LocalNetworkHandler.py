import sys
import re
sys.path.append('cluster_api')
import LocalMachine
import socket

class ClusterMemberDiscover():

    def __init__(self):
        self.devices_on_network_raw = {}
        self.devices_on_network = {}
        self.network_mapper_raw()
        self.device_mapper_inject_hostname_data()

    def validate_ip(self, addr):
        try:
            socket.inet_aton(addr)
            return True
        except socket.error:
            return False

    def network_mapper_raw(self, debug_print=False):
        print("[ClusterMemberDiscover] [arp-scan] get raw local network data")
        exitcode, stdout, stderr = LocalMachine.run_command("sudo arp-scan -l")
        local_machines_info_list = stdout.split("\n")
        for local_machines_info in local_machines_info_list:
            values = local_machines_info.split("\t")
            if self.validate_ip(values[0]):
                try:
                    self.devices_on_network_raw[str(values[0]).strip()] = [str(values[1]).strip(),\
                                       str(values[2]).strip(), "hostname"]
                except:
                    pass

        if debug_print:
            for key, value in self.devices_on_network_raw.items():
                print("IP: {}\n\tDATA: {}".format(key, value))

    def device_mapper_inject_hostname_data(self, debug_print=True):
        print("[ClusterMemberDiscover] [nbtscan] get hostname by ip, create compact network data")
        for key, value in self.devices_on_network_raw.items():
            exitcode, stdout, stderr = LocalMachine.run_command("nbtscan " +  str(key))
            stdout_lines = stdout.split("\n")
            cnt = 0
            for index, line in enumerate(stdout_lines):
                line_worlds = re.split('\s+', line)
                if key in line_worlds[0]:
                    hostname = line_worlds[1]
                    self.devices_on_network[hostname] = {"ip": str(key), "mac": str(value[0]), "device": str(value[1])}
                else:
                    hostname = "UNKNOWN-" + str(cnt)
                    cnt+=1
                    self.devices_on_network[hostname] = {"ip": str(key), "mac": str(value[0]), "device": str(value[1])}

        if debug_print:
            for key, value in self.devices_on_network.items():
                print("{}\n\t{}".format(key, value))

    def get_devices_on_network_data(self):
        return self.devices_on_network


if __name__ == "__main__":
    discover_obj = ClusterMemberDiscover()
    devices_on_network_data = discover_obj.get_devices_on_network_data()
