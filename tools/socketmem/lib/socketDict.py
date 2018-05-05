import socket
import sys
from thread import *

class SocketServer():

    def __init__(self, host='', port=8888):
        self.silentmode = True
        self.host = host
        self.port = port
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.serverside_printout("Socket created: HOST: {} PORT: {}".format(self.host, self.port))
        self.bind_socket()
        self.server_core()

    def bind_socket(self):
        #Bind socket to local host and port
        try:
            self.s.bind((self.host, self.port))
        except socket.error as msg:
            self.serverside_printout("Bind failed. Error Code : " + str(msg[0]) + " Message " + msg[1])
            sys.exit()
        self.serverside_printout("Socket bind complete")

        #Start listening on socket
        self.s.listen(10)
        self.serverside_printout("Socket now listening")

    #Function for handling connections. This will be used to create threads
    def __clientthread(self, conn):
        #Sending message to connected client
        self.send(conn, '[ThreadClient] Welcome to the server. For exit, type exit.\n') #send only takes string
        #infinite loop so that function do not terminate and thread do not end.
        while True:
            #Receiving from client
            data = conn.recv(1024)
            cmd, reply = self.input_data_handler(data)
            self.send_all(conn, reply)
            if cmd == "break":
                break
        #came out of loop
        conn.close()

    def send(self, conn, msg, force=False):
        if not self.silentmode or force:
            conn.send(str(msg))

    def send_all(self, conn, msg, force=False):
        if not self.silentmode or force:
            conn.sendall(str(msg))

    def server_core(self):
        #now keep talking with the client
        while 1:
            #wait to accept a connection - blocking call
            conn, addr = self.s.accept()
            self.serverside_printout("[NewConnection] Connected with " + addr[0] + ":" + str(addr[1]))
            #start new thread takes 1st argument as a function name to be run, second is the tuple of arguments to the function.
            start_new_thread(self.__clientthread ,(conn,))
        self.s.close()

    def input_data_handler(self, data):
        data = data.rstrip()
        if data == "exit":
            return "break", "Goodbye :)\n"
        elif not data:
            return "break", None
        else:
            # TODO: call advanced interpreter here
            return None, "MSG: " + str(data) + "\n"

    def serverside_printout(self, text):
        print("[SocketServer] " + str(text))

    def __del__(self):
        self.s.close()

if __name__ == "__main__":
    try:
        socketserver = SocketServer()
    except KeyboardInterrupt:
        pass
