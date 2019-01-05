import socketHandler
import jsonHandler
import LogHandler
mylogger = LogHandler.LogHandler("dictSocketHandlerCore")

class dictHandler(socketHandler.SocketServer):

    def __init__(self, host='', port=8888, silentmode=False, only_internal_mode=True):
        self.silentmode=silentmode
        self.MEM_DICT = {}
        self.dict_backup_handler = None
        self.init_MEM_DICT()
        socketHandler.SocketServer.__init__(self, host, port, silentmode, only_internal_mode=only_internal_mode)

    def init_MEM_DICT(self):
        self.dict_backup_handler = jsonHandler.jsonHandler()
        self.MEM_DICT = self.dict_backup_handler.read_cfg_file()
        self.MEM_DICT["general"] = { "service": "rpitools",
                                     "born": "around 2018"
                                   }
        self.serverside_printout("Init state: " + str(self.dict_backup_handler.write_cfg_file(self.MEM_DICT)))
        self.serverside_printout("Full dict: " + str(self.MEM_DICT))

    def input_data_handler(self, data):
        silentmode_text = ""
        cmd, text, silentmode_text = socketHandler.SocketServer.input_data_handler(self, data)
        self.serverside_printout("Toplvl script active")
        cmd, text, silentmode_text = self.dict_handler_interpreter(data, cmd, text)
        return cmd, text, silentmode_text

    def dict_handler_interpreter(self, data, cmd, text):
        data = data.rstrip()
        self.serverside_printout("data: {}\ncmd: {}\ntext:{}".format(data, cmd, text))
        output_text=""
        silentmode_text = ""

        if cmd != "break":
            arg_list = data.split(" ")
            is_known = False

            if "-s" in arg_list or "--silent" in arg_list:
                is_known = True
                for index_, arg_ in enumerate(arg_list):
                    if "-s" in arg_list or "--silent" in arg_list:
                        try:
                            if arg_list[index_+1] == "True":
                                silent_direct_state = True
                            elif arg_list[index_+1] == "False":
                                silent_direct_state = False
                            else:
                                raise Exception("Not bool [True/False]: " + str(arg_list[index_+1]))
                            self.silentmode = silent_direct_state
                            self.serverside_printout("silent mode direct set: {}".format(self.silentmode))
                            break
                        except Exception as e:
                            mylogger.logger.error("EXCEPTION: {}".format(e))
                            mylogger.logger.error("silent mode automatic set: {}".format(self.silentmode))
                            self.silentmode = not self.silentmode
                if self.silentmode is False:
                    output_text += "Silent mode OFF\n"

            if "-sh" in arg_list or "--show" in arg_list:
                is_known = True
                output_text += self.__show_dict(data)
                silentmode_text = output_text
                self.serverside_printout(output_text)

            if "-md" in arg_list or "--memdict" in arg_list:
                is_known = True
                output_text_, silentmode_text = self.__dicthandler(data)
                output_text += output_text_
                self.serverside_printout(output_text)

            if "-st" in arg_list or "--statistic" in arg_list:
                is_known = True
                output_text_, silentmode_text = self.__stathandler(data)
                output_text += output_text_
                self.serverside_printout(output_text)


            if "-h" in arg_list or "--help" in arg_list:
                is_known = True
                output_text += "\tDETAILS:\n"
                output_text += "\t-sh [--show]\t-\tshow dictionary ( ram ) content.\n"
                output_text += "\t-md [--memdict]\t-\tmemory dict handler -n [--namespace] | -k [--key] | -v [--value]\n"
                output_text += "\t-s [--silent]\t-\tsilent mode.\n"
                output_text += "\t-st [--statistic]\t-\tshows usage statistic.\n"
                output_text += "\t-h [--help]\t-\tthis help msg.\n"

                output_text += "\n\tFor exit type: exit\n"
                silentmode_text = output_text

            if not is_known:
                output_text+="UNKOWN ARGUMENT IN " + str(arg_list)

            return cmd, output_text, silentmode_text

        else:
            return cmd, text, silentmode_text

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

    def __stathandler(self, data):
        char_size_byte = 1
        mem_dict_size_byte = len(str(self.MEM_DICT)) * char_size_byte
        text = "\tCONNECTED CLIENTS: " + str(self.connected_clients) + "\n"
        text += "\tMemDict size: {} byte".format(mem_dict_size_byte)
        output_text = silentmode_text = text
        return output_text, silentmode_text

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

        mylogger.logger.info("NAMSEPACEin: {}\nKEYin: {}\nVALUEin: {}\n".format(namespace_in, key_in, value_in))

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
                        silentmode_text = True
                    else:
                        output_text += "\tFAIL"
                        silentmode += False
                except Exception as e:
                    output_text += "Override value error: " + str(e) + "\n"
            else:
                # we have namespace and key
                try:
                    output_text += "GET VALUE [{}][{}]\n".format(namespace_in, key_in)
                    output_text += str(self.MEM_DICT[namespace_in][key_in])
                    silentmode_text = str(self.MEM_DICT[namespace_in][key_in])
                except Exception as e:
                    output_text += "Get value error: " + str(e)
        else:
            # just namespace_in we have - show all namespace
            try:
                output_text += "GET FULL NAMESPACE [{}]\n".format(namespace_in)
                output_text += str(self.MEM_DICT[namespace_in])
                silentmode_text = str(self.MEM_DICT[namespace_in])
            except Exception as e:
                output_text += "Get namespace error: " + str(e)

        return output_text, silentmode_text

if __name__ == "__main__":
    dicthandler = dictHandler()
