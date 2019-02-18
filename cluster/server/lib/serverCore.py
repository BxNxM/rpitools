import sys
import re
sys.path.append('cluster_api')
import LocalNetworkHandler
import jsonHandler

class ClasterCoreService():

    def __init__(self):
        self.data_handlers = {}
        self.__create_data_json("cluster_detected_devices")
        self.__network_device_scanner()

    def __network_device_scanner(self):
        discover_obj = LocalNetworkHandler.ClusterMemberDiscover()
        devices_on_network_data = discover_obj.get_devices_on_network_data()
        self.__write_config_file("cluster_detected_devices", devices_on_network_data)

    def __create_data_json(self, data_name):
        self.data_handlers[str(data_name).upper()] = jsonHandler.jsonHandler(data_name)

    def __write_config_file(self, data_name, data_dict):
        data_handler = self.data_handlers[str(data_name).upper()]
        data_handler.write_cfg_file(data_dict, retry=10, delay=0.1)

    def __background_threads(self):
        # TODO
        self.__network_device_scanner()

if __name__ == "__main__":
    cluster_serverc = ClasterCoreService()
