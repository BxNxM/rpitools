#!/usr/bin/python

import sys
import socket
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(myfolder)
import ast
import select

print('Number of arguments: ' + str(len(sys.argv)) + ' arguments.')
print('Argument List: ' + str(sys.argv))

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

    def get_parameter(self, namespace, key):
        cmd = "-md -s True -n {} -k {}".format(namespace, key)
        msg = self.run_command(cmd)
        return msg

    def set_parameter(self, namespace, key, value):
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

if __name__ == "__main__":
    try:
        socketdictclient = SocketDictClient()
    except KeyboardInterrupt:
        pass

    # handle argumentum list
    if len(sys.argv) > 1:
        arg_list = sys.argv[1:]
        cmd = ""
        for par in arg_list:
            cmd += " " + str(par)
        socketdictclient.receive_data()
        print(socketdictclient.run_command(cmd))

    if len(sys.argv) == 2:
        if sys.argv[1] == "-h" or sys.argv[1] == "--help":
            print("(1) RUN COMMAND: clientMemDict -md -n xx -k yy -v zz\n\tOR: clientMemDict --memDict --namespace xx --key yy --value zz")
            print("(2) RUN INTERACTIVE MODE: clientMemDict")

    if len(sys.argv) == 1:
        try:
            socketdictclient.interactive_core()
        except KeyboardInterrupt:
            socketdictclient.close_connection()
