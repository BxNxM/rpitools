import sys
sys.path.append('cluster_api')
import socketHandler

class ClasterSocketServer(socketHandler.SocketServer):

    def __init__(self):
        self.state_machine = {"start_handshake": False}
        socketHandler.SocketServer.__init__(self)

    def input_data_handler(self, data):
        silentmode_text = ""
        cmd, text, silentmode_text = socketHandler.SocketServer.input_data_handler(self, data)
        print("Toplvl script active")
        cmd, text, silentmode_text = self.clusterInterpreter(data, cmd, text)
        return cmd, text, silentmode_text

    def clusterInterpreter(self, data, cmd, text):
        silentmode_text = "silent text"
        text = "text"
        cmd = "cmd"
        print("{}\n{}\n{}".format(data, cmd, text))
        # AUTHORIZE
        #data = self.__handshake(data)
        #if data != "echooo":
        #    data = self.__auth_by_claster_UUID(data)
        return cmd, data, silentmode_text

    def __handshake(self, data):
        data = data.strip()
        if data == "echo":
            self.state_machine["start_handshake"] = True
            return "echooo"
        else:
            return data

    def __auth_by_claster_UUID(self, data):
        claster_UUID = "12345"
        data = data.strip()
        if self.state_machine["start_handshake"]:
            if data == claster_UUID:
                self.state_machine["start_handshake"] = False
                return "Authorized, adding mac address to friendly claster members"
            else:
                self.state_machine["start_handshake"] = False
                return "Unauthorized, friendly claster UUID not matched!"
        else:
            self.state_machine["start_handshake"] = False
            return data

if __name__ == "__main__":
    while True:
        try:
            ClasterSocketServer()
        except KeyboardInterrupt:
            break
        except Exception as e:
            print("UNEXPECTED MAIN ERROR: " + str(e))
