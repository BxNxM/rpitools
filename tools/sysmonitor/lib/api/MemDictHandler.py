import sys
import os
myfolder = os.path.dirname(os.path.abspath(__file__))

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

clientMemDict_path = os.environ['CLIENTMEMDICT']
import LocalMachine

def __debug_print(cmd, activate=False):
    if activate:
        print(cmd)

def get_value_MemDict(key, namespace="system", field=None):
    global clientMemDict_path
    if field is not None:
        cmd = "{} -md -n {} -f {} -k {} -s True".format(clientMemDict_path, namespace, field, key)
    else:
        cmd = "{} -md -n {} -k {} -s True".format(clientMemDict_path, namespace, key)
    __debug_print(cmd)
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
        cmd = "{} -md -n {} -f {} -k {} -v {} -s True".format(clientMemDict_path, namespace, field, key, value)
    else:
        cmd = "{} -md -n {} -k {} -v {} -s True".format(clientMemDict_path, namespace, key, value)
    __debug_print(cmd)
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
