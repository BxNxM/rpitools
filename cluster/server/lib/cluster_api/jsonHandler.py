import json
import os
import sys
import time
myfolder = os.path.dirname(os.path.abspath(__file__))
data_folder_path = str(myfolder) + "/../../claster_data/"

class jsonHandler():
    def __init__(self, cfg_name):
        global data_folder_path
        self.cfg_path = data_folder_path + os.sep + cfg_name + ".json"
        self.file_last_modified_date = 0
        if not os.path.exists(self.cfg_path):
            open(self.cfg_path, 'a').close()
            print("Create bacup file {} in {}".format(cfg_name, data_folder_path))

    # EXTERNAL FUNCTIONS - GET VALUE
    def get(self, key):
        config = self.read_cfg_file()
        try:
            value = config[key]
        except:
            value = None
        return value

    # EXTERNAL FUNCTION - GET ALL
    def get_all(self):
        config = self.read_cfg_file()
        return config

    # EXTERNAL FUNCTION - PUT VALUE
    def put(self, key, value):
        config = self.read_cfg_file()
        config[key] = value
        self.write_cfg_file(config)

    # FILE IS MODIFIED CHECK
    def file_is_modified(self):
        moddate_raw = os.stat(self.cfg_path)[8]           # modification date
        moddate_hr = time.ctime(moddate_raw)            # human readable mod date
        is_modified = False
        if moddate_raw != self.file_last_modified_date:
            self.file_last_modified_date = moddate_raw
            is_modified = True
        return is_modified

    def write_cfg_file(self, dictionary, retry=10, delay=0.1):
        while retry > 0:
            try:
                with open(self.cfg_path, 'w') as f:
                    json.dump(dictionary, f, sort_keys=True, indent=2)
                    return True
            except Exception as e:
                print("ConfigHandler.write_cfg_file write json: " + str(e))
                retry -= 1
                time.sleep(delay)
        print("write_cfg_file")
        return False

    def read_cfg_file(self, retry=10, delay=0.1):
        while retry > 0:
            try:
                with open(self.cfg_path, 'r') as f:
                    data_dict = json.load(f)
                    return data_dict
            except Exception as e:
                print("ConfigHandler.read_cfg_file write json: " + str(e))
                retry -= 1
                time.sleep(delay)
        print("[ERROR] read_cfg_file")
        data_dict = {}
        return data_dict

    def inject_schema(self, dict_schema):
        try:
            actaul_dict = self.get_all()
            print("after load: " + str(actaul_dict))
            for namespace, appdict in dict_schema.iteritems():
                if namespace not in actaul_dict.keys():
                    print("Add new namespace")
                    actaul_dict[namespace] = {}
                for key, value in appdict.iteritems():
                    if key not in actaul_dict[namespace].keys():
                        print("Create key: {} in namespace: {} with value: {}".format(key, namespace, value))
                        actaul_dict[namespace][key] = value
            self.write_cfg_file(actaul_dict)
            return True
        except:
            return False

def init_data_folder():
    global data_folder_path
    if not os.path.exists(data_folder_path):
        os.makedirs(data_folder_path)

if "jsonHandler" in __name__:
    init_data_folder()

if __name__ == "__main__":
    init_data_folder()
    dict_backup = jsonHandler("foo")
