#!/usr/bin/python

import sys
import socket
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(myfolder)
import ast
import select
import LocalMachine
dumped_dotdictbackup_json_path = myfolder + os.sep + ".dictbackup.json"

#print('Number of arguments: ' + str(len(sys.argv)) + ' arguments.')
#print('Argument List: ' + str(sys.argv))

class SocketDictClient():

    def __init__(self, bufsize=1024, host='localhost', port=8888):
        self.bufsize = bufsize
        self.host = host
        self.port = port
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect(('localhost', 8888))

    def run_command(self, cmd, info=False):
        cmd = str.encode(cmd)
        self.conn.send(cmd)
        data = self.receive_data()
        if info:
            msglen = len(data)
            print("got: {}".format(data))
            print("received: {}".format(msglen))
        if data == '\0':
            print('exiting...')
            self.close_connection()
            sys.exit(0)
        return data.strip()

    def receive_data(self):
        if select.select([self.conn], [], [], 1)[0]:
            data = self.conn.recv(self.bufsize)
        else:
            data = ""
        return data.strip()

    def interactive_core(self):
        sys.stdout.write(self.receive_data())
        sys.stdout.flush()
        while True:
            cmd = raw_input()
            if cmd != "":
                sys.stdout.write(self.run_command(cmd))
                sys.stdout.flush()
                if cmd.rstrip() == "exit":
                    self.close_connection()
                    sys.exit(0)

    def get_parameter(self, namespace, key, field=None):
        if field is not None:
            cmd = "-md -s True -n {} -f {} -k {}".format(namespace, field, key)
        else:
            cmd = "-md -s True -n {} -k {}".format(namespace, key)
        msg = self.run_command(cmd)
        return msg

    def set_parameter(self, namespace, key, value, field=None):
        if field is not None:
            cmd = "-md -s True -n {} -f {} -k {} -v {}".format(namespace, field, key, value)
        else:
            cmd = "-md -s True -n {} -k {} -v {}".format(namespace, key, value)
        msg = self.run_command(cmd)
        return msg

    def string_to_dict(self, appdict):
        try:
            return ast.literal_eval(appdict)
        except:
            return None

    def close_connection(self):
        self.run_command("exit")

def reset_dumped_database_and_restart_service():
    global dumped_dotdictbackup_json_path
    cmd = "rm -f " + str(dumped_dotdictbackup_json_path)
    exit_code, stdout, stderr = LocalMachine.run_command(cmd, wait_for_done=True)
    if exit_code == 0:
        cmd = "sudo systemctl restart memDictCore"
        exit_code, stdout, stderr = LocalMachine.run_command(cmd, wait_for_done=True)
        if exit_code == 0:
            cmd = "sudo systemctl is-active memDictCore"
            exit_code, stdout, stderr = LocalMachine.run_command(cmd, wait_for_done=True)
            if stdout == "active":
                print("Reset memDictCore databse was SUCCESSFUL")
            else:
                print("Reset memDictCore databse FAILED: " + str(stdout))
        else:
            print("Reset memDictCore databse FAILED: " + str(stderr))
    else:
        print("Reset memDictCore databse FAILED: " + str(stderr))
    return exit_code

if __name__ == "__main__":
    try:
        socketdictclient = SocketDictClient()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print("FAILED TO START: " + str(e))

    # handle argumentum list
    if len(sys.argv) == 2:
        if sys.argv[1] == "-h" or sys.argv[1] == "--help":
            print("(1) RUN COMMAND: clientMemDict -md -n xx -k yy -v zz\n\tOR: clientMemDict --memdict --namespace xx --key yy --value zz")
            print("(2) RUN COMMAND: clientMemDict -md -n xx -f mm -k yy -v zz\n\tOR: clientMemDict --memdict --namespace xx --field mm --key yy --value zz")
            print("(3) RUN INTERACTIVE MODE: clientMemDict")
            print("TOOLS: RESET AND RESTART MEMDICT SERVICE: clientMemDict -r | --reset")
            print("TOOLS: RUN TEST MODULE: clientMemDict -tm | --testmodule")
            sys.exit(0)
        if sys.argv[1] == "-r" or sys.argv[1] == "--reset":
            print("Reset memory dict core")
            exit_code = reset_dumped_database_and_restart_service()
            sys.exit(exit_code)
        if sys.argv[1] == "-tm" or sys.argv[1] == "--testmodule":
            print("Run service test module, pls wait...")
            print("CMD: " + str(myfolder) + "/../testmodule/test_memdict_cmdline_interface.bash")
            if str(raw_input("RUN? Y|N > ")).lower() == "y":
                exit_code, stdout, stderr = LocalMachine.run_command(str(myfolder) + "/../testmodule/test_memdict_cmdline_interface.bash")
                print(stdout)
            else:
                exit_code = 0
            sys.exit(exit_code)

    if len(sys.argv) > 1:
        arg_list = sys.argv[1:]
        cmd = ""
        for par in arg_list:
            cmd += " " + str(par)
        socketdictclient.receive_data()
        print(socketdictclient.run_command(cmd))

    if len(sys.argv) == 1:
        try:
            socketdictclient.interactive_core()
        except KeyboardInterrupt:
            socketdictclient.close_connection()
