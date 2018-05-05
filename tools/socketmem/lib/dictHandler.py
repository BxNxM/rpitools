import socketHandler
import jsonHandler

class dictHandler(socketHandler.SocketServer):

    def __init__(self, host='', port=8888):
        self.silentmode=False
        self.MEM_DICT = {}
        self.dict_backup_handler = None
        self.init_MEM_DICT()
        socketHandler.SocketServer.__init__(self, host, port)

    def init_MEM_DICT(self):
        self.dict_backup_handler = jsonHandler.jsonHandler()
        self.MEM_DICT = self.dict_backup_handler.read_cfg_file()
        self.MEM_DICT["general"] = { "service": "rpitools",
                                       "born": "around 2018"
                                   }

        self.serverside_printout("Init state: " + str(self.dict_backup_handler.write_cfg_file(self.MEM_DICT)))
        self.serverside_printout("Full dict: " + str(self.MEM_DICT))

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
                output_text += self.__show_dict(data)
                self.serverside_printout(output_text)

            if "-md" in arg_list or "--memdict" in arg_list:
                is_known = True
                output_text += self.__dicthandler(data)
                self.serverside_printout(output_text)

            if "-h" in arg_list or "--help" in arg_list:
                is_known = True
                output_text += "\tDETAILS:\n"
                output_text += "\t-sh [--show]\t-\tshow dictionary ( ram ) content.\n"
                output_text += "\t-md [--memdict]\t-\tmemory dict handler -n [--namespace] | -k [--key] | -v [--value]\n"
                output_text += "\t-h [--help]\t-\tthis help msg.\n"

                output_text += "\n\tFor exit type: exit\n"

            if not is_known:
                output_text+="UNKOWN ARGUMENT IN " + str(arg_list)

            return cmd, output_text

        else:
            return cmd, text

    def __show_dict(self, data):
        formatteddict = "SHOW DICTIONARY CONTENT:\n"
        try:
            for namespace, appdict in self.MEM_DICT.iteritems():
                formatteddict += str(namespace) + "\n"
                for appdict_key, appdict_value in appdict.iteritems():
                    formatteddict += "\t" + str(appdict_key) + " : " + str(appdict_value) + "\n"
        except:
            formatteddict = str(self.MEM_DICT)
        return formatteddict

    def __dicthandler(self, data):
        data = data.rstrip()
        data_list = data.split(" ")
        namespace_in = None
        key_in = None
        value_in = None
        output_text = ""
        try:
            for index, value in enumerate(data_list):
                if value == "-n" or value == "--namespace":
                    if "-" not in data_list[index+1] and "--" not in data_list[index+1]:
                            namespace_in = data_list[index+1]
                if value == "-k" or value == "--key":
                    if "-" not in data_list[index+1] and "--" not in data_list[index+1]:
                        key_in = data_list[index+1]
                if value == "-v" or value == "--value":
                    if "-" not in data_list[index+1] and "--" not in data_list[index+1]:
                        value_in = data_list[index+1]
        except:
            output_text += "Missing argument - index out of range"

        print("NAMSEPACEin: {}\nKEYin: {}\nVALUEin: {}\n".format(namespace_in, key_in, value_in))

        if namespace_in is None:
            output_text += "SET DEFAULT NAMESPACE [general]\n"
            namespace_in = "general"
        else:
            output_text += "SELECTED NAMESPACE: " + namespace_in + "\n"
            if namespace_in not in self.MEM_DICT.keys():
                self.serverside_printout("Create new namespace: " + str(namespace_in))
                self.MEM_DICT[namespace_in] = {}

        if key_in is not None:
            if value_in is not None:
                # new value - override
                try:
                    try:
                        value = self.MEM_DICT[namespace_in][key_in]
                    except:
                        value=None
                    output_text += "OVERRIDE VALUE [{}][{}][{}] -> [{}][{}][{}]\n".format(namespace_in, key_in, value,\
                                                                                        namespace_in, key_in, value_in)
                    self.MEM_DICT[namespace_in][key_in] = value_in
                    if self.dict_backup_handler.write_cfg_file(self.MEM_DICT):
                        output_text += "\tSUCCESS"
                    else:
                        output_text += "\tFAIL"
                except Exception as e:
                    output_text += "Override value error: " + str(e) + "\n"
            else:
                # we have namespace and key
                try:
                    output_text += "GET VALUE [{}][{}]\n".format(namespace_in, key_in)
                    output_text += str(self.MEM_DICT[namespace_in][key_in])
                except Exception as e:
                    output_text += "Get value error: " + str(e)
        else:
            # just namespace_in we have - show all namespace
            try:
                output_text += "GET FULL NAMESPACE [{}]\n".format(namespace_in)
                output_text += str(self.MEM_DICT[namespace_in])
            except Exception as e:
                output_text += "Get namespace error: " + str(e)

        return output_text

if __name__ == "__main__":
    dicthandler = dictHandler()
