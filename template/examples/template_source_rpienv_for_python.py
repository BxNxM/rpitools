import pprint
import os
import sys

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

if __name__ == "__main__":
    # GET RPIENV DICT
    pprint.pprint(dict(os.environ))

    # GET RPIENV VALUE
    try:
        CONFIGHANDLER = os.environ['CONFIGHANDLER']
    except KeyError:
        CONFIGHANDLER = None

    # IMPORT AS PYTHON MODULE
    lib_path = os.path.join(os.path.dirname(os.environ['CONFIGHANDLERPY']))
    sys.path.append(lib_path)
    import ConfigHandler
