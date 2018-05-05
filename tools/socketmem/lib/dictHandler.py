import socketHandler

class dictHandler(socketHandler.SocketServer):

    def __init__(self, host='', port=8888):
        socketHandler.SocketServer.__init__(self, host, port)
        self.silentmode=False

    def input_data_handler(self, data):
        cmd, text = socketHandler.SocketServer.input_data_handler(self, data)
        self.serverside_printout("Toplvl script active")
        cmd, text = self.dict_handler_interpreter(data, cmd, text)
        return cmd, text

    def dict_handler_interpreter(self, data, cmd, text):
        data = data.rstrip()
        self.serverside_printout("data: {}\ncmd: {}\ntext:{}".format(data, cmd, text))
        output_text=""
        if cmd != "break":
            arg_list = data.split(" ")
            is_known = False
            if "-sh" in arg_list or "--show" in arg_list:
                is_known = True
                output_text+="SHOW DICT"
                self.serverside_printout(output_text)

            if not is_known:
                output_text+="UNKOWN ARGUMENT IN " + str(arg_list)

            return cmd, output_text
        else:
            return cmd, text

if __name__ == "__main__":
    dicthandler = dictHandler()
