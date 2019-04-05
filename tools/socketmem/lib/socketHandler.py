import socket
import sys
from thread import *
import time
import LogHandler
mylogger = LogHandler.LogHandler("dictSocketHandlerCore")

class SocketServer():

    def __init__(self, host='', port=8888, silentmode=True, only_internal_mode=True):
        self.serverside_printout("=> Initialize SocketServer")
        self.silentmode = silentmode
        self.prompt = "> "
        self.host = host
        self.port = port
        self.connected_clients=0
        self.only_internal_mode = only_internal_mode
        self.start_socket_server()

    def start_socket_server(self):
        self.serverside_printout("=> Start socket server")
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        mylogger.logger.warn("[INFO] Socket created: HOST: {} PORT: {}".format(self.host, self.port))

        self.bind_socket()
        self.server_core()

    def bind_socket(self, retry=20):
        self.serverside_printout("=> Attampt to bind socket: {}:{}".format(self.host, self.port))
        for cnt in range(0, retry):
            #Bind socket to local host and port
            try:
                self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                self.s.bind((self.host, self.port))
                self.serverside_printout("\t=> Socket bind complete")
                break
            except socket.error as msg:
                mylogger.logger.error("\t=> Bind failed. Error Code : " + str(msg[0]) + " Message " + msg[1])
                time.sleep(4)
        if cnt == retry:
            sys.exit()

        #Start listening on socket
        self.s.listen(10)
        self.serverside_printout("\t=> Socket now listening")

    #Function for handling connections. This will be used to create threads
    def __clientthread(self, conn):
        self.serverside_printout("\t\t=> Start client thread, conn: " + str(conn))
        if not self.silentmode:
            prompt = self.prompt
        else:
            prompt = ""
        #Sending message to connected client
        self.send(conn, '[ThreadClient] Welcome in the MEMDICT socket server. For exit, type exit.\nFor more info type: -h\n' + prompt) #send only takes string
        #infinite loop so that function do not terminate and thread do not end.
        while True:
            if not self.silentmode:
                prompt = self.prompt
            else:
                prompt = ""
            #Receiving from client
            data = conn.recv(1024)
            cmd, reply, silent_text = self.input_data_handler(data, conn)
            self.send_all(conn, str(reply) + "\n" + prompt)
            if self.silentmode is True:
                self.send_all(conn, str(silent_text) + "\n", force=True)
            if cmd == "break":
                break
        #came out of loop
        self.serverside_printout("\t\t=> Close connection: " + str(conn) + " [ " + str(self.connected_clients) + " connection left ]")
        conn.close()

    def send(self, conn, msg, force=False):
        if not self.silentmode or force:
            conn.send(str(msg))

    def send_all(self, conn, msg, force=False):
        if not self.silentmode or force:
            conn.sendall(str(msg))

    def server_core(self):
        self.serverside_printout("\t=> Start server core")
        #now keep talking with the client
        while True:
            #wait to accept a connection - blocking call
            conn, addr = self.s.accept()
            if "127.0.0.1" == str(addr[0]):
                mylogger.logger.warn("[INFO] [NewConnection] [internal] Connected with " + addr[0] + ":" + str(addr[1]))
                self.connected_clients += 1
                #start new thread takes 1st argument as a function name to be run, second is the tuple of arguments to the function.
                self.serverside_printout("\t=> Start client thread from server_core - iface: lo")
                start_new_thread(self.__clientthread ,(conn,))
            else:
                mylogger.logger.warn("[INFO] [NewConnection] [external] Connected with " + addr[0] + ":" + str(addr[1]))
                if self.only_internal_mode:
                    self.serverside_printout("\t=> Drop client thread from server_core, only_internal_mode: " + str(self.only_internal_mode))
                    mylogger.logger.warn("[INFO] [NewConnection] [external] - only_internal_mode: {} - DROP".format(self.only_internal_mode))
                    conn.close()
                else:
                    self.connected_clients += 1
                    #start new thread takes 1st argument as a function name to be run, second is the tuple of arguments to the function.
                    self.serverside_printout("\t=> Start client thread from server_core - iface: external: eth0/wlan0/etc")
                    start_new_thread(self.__clientthread ,(conn,))
        self.s.close()

    def input_data_handler(self, data, conn=None):
        self.serverside_printout("\t\t=> Run input_data_handler conn: " + str(conn))
        self.serverside_printout("\t\t\t=> Run input_data_handler data: " + str(data))
        data = data.rstrip()
        if data == "exit":
            self.connected_clients -= 1
            return "break", None, "Data: " + str(data) + "Goodbye :)"
        elif not data:
            self.connected_clients -= 1
            return "break", None, "No Data, Goodbye"
        else:
            # TODO: call advanced interpreter here
            return None, str(data), "MSG: " + str(data)

    def serverside_printout(self, text):
        try:
            silentmode = self.silentmode
        except:
            silentmode = None
        msg = "[SocketServer] [silent:" + str(silentmode) + "] " + str(text)
        mylogger.logger.info(msg)

    def __del__(self):
        self.s.close()

if __name__ == "__main__":
    while True:
        try:
            socketserver = SocketServer()
        except KeyboardInterrupt:
            mylogger.logger.warn("Keyboard interrupt.")
            break
        except Exception as e:
            mylogger.logger.error("UNEXPECTED MAIN ERROR: " + str(e))
