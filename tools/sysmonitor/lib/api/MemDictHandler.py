import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
clientMemDict_path = os.path.join(myfolder, "../../../socketmem/lib/clientMemDict.py")
import LocalMachine

def get_value_MemDict(key, namespace="system", field=None):
    global clientMemDict_path
    if field is not None:
        cmd = "{} -md -n {} -f {} -k {}".format(clientMemDict_path, namespace, field, key)
    else:
        cmd = "{} -md -n {} -k {}".format(clientMemDict_path, namespace, key)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd, wait_for_done=True)
    if exitcode == 0:
        value = stdout
    else:
        print("Get data from memdict failed: {}\n{}".format(cmd, stderr))
        value = None
    return value

def set_value_MemDict(key, value, namespace="system", field=None):
    global clientMemDict_path
    if field is not None:
        cmd = "{} -md -n {} -f {} -k {} -v {}".format(clientMemDict_path, namespace, field, key, value)
    else:
        cmd = "{} -md -n {} -k {} -v {}".format(clientMemDict_path, namespace, key, value)
    exitcode, stdout, stderr = LocalMachine.run_command(cmd, wait_for_done=True)
    if exitcode == 0:
        state = stdout
    else:
        print("Get data from memdict failed: {}\n{}".format(cmd, stderr))
        state = None
    return state

def set_value_metadata_info(value, key="info", namespace="system", field="metadata"):
    return set_value_MemDict(key, value, namespace="system", field=field)

def get_value_metadata_info(key="info", namespace="system", field="metadata"):
    return get_value_MemDict(key=key, namespace="system", field=field)

if __name__ == "__main__":
    print("write value: linux_services = " + str(set_value_MemDict(key="linux_services", value="testOK")))
    print("get value: linux_services = " + str(get_value_MemDict(key="linux_services")))

    print("write metadata info value: " + str(set_value_metadata_info("'test info text'")))
    print("get metadata info value: " +str(get_value_metadata_info()))
