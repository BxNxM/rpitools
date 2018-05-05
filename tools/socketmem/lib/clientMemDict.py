import sys
import socket

class SocketDictClient():

    def __init__(self, bufsize=1024, host='localhost', port=8888):
        self.bufsize = bufsize
        self.host = host
        self.port = port
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect(('localhost', 8888))

    def run_command(self, cmd, info=False):
        self.conn.send(cmd)
        data = self.conn.recv(self.bufsize)
        if info:
            msglen = len(data)
            print "got: %s" % data
            print "received: %d" % msglen
        if data == '\0':
            print 'exiting...'
            sys.exit(0)
        return data.rstrip()

    def interactive_core(self):
        while True:
            cmd = raw_input('Enter a command: ')
            print(self.run_command(cmd))

    def get_parameter(self, namespace, key):
        cmd = "-md -s True -n {} -k {}".format(namespace, key)
        msg = socketdictclient.run_command(cmd)
        return msg

    def set_parameter(self, namespace, key, value):
        cmd = "-md -s True -n {} -k {} -v {}".format(namespace, key, value)
        msg = socketdictclient.run_command(cmd)
        return msg

if __name__ == "__main__":
    try:
        socketdictclient = SocketDictClient()
    except KeyboardInterrupt:
        pass

    print("Get LED status: " + socketdictclient.get_parameter(namespace="rgb", key="LED"))
    print("Set Led status to ON, success: " + socketdictclient.set_parameter(namespace="rgb", key="LED", value="ON"))
    print("Get LED status: " + socketdictclient.get_parameter(namespace="rgb", key="LED"))
    print("Set Led status to OFF, success: " + socketdictclient.set_parameter(namespace="rgb", key="LED", value="OFF"))



