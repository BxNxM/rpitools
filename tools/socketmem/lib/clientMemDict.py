import sys
import socket
import os
myfolder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(myfolder)

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
        data = self.conn.recv(self.bufsize)
        if info:
            msglen = len(data)
            print("got: {}".format(data))
            print("received: {}".format(msglen))
        if data == '\0':
            print('exiting...')
            sys.exit(0)
        return data.rstrip()

    def interactive_core(self):
        while True:
            cmd = raw_input('Enter a command: ')
            print(self.run_command(cmd))

    def get_parameter(self, namespace, key):
        cmd = "-md -s True -n {} -k {}".format(namespace, key)
        msg = self.run_command(cmd)
        return msg

    def set_parameter(self, namespace, key, value):
        cmd = "-md -s True -n {} -k {} -v {}".format(namespace, key, value)
        msg = self.run_command(cmd)
        return msg

if __name__ == "__main__":
    try:
        socketdictclient = SocketDictClient()
    except KeyboardInterrupt:
        pass

    if len(sys.argv) > 1:
        arg_list = sys.argv[1:]
        cmd = ""
        for par in arg_list:
            cmd += " " + str(par)
        print(socketdictclient.run_command(cmd))

    else:
        print("Get LED status: " + str(socketdictclient.get_parameter(namespace="rgb", key="LED")))
        print("Set Led status to ON, success: " + str(socketdictclient.set_parameter(namespace="rgb", key="LED", value="ON")))
        print("Get LED status: " + str(socketdictclient.get_parameter(namespace="rgb", key="LED")))
        print("Set Led status to OFF, success: " + str(socketdictclient.set_parameter(namespace="rgb", key="LED", value="OFF")))


