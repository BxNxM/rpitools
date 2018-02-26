import ConfigParser
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(myfolder, "../config/rpitools_config.cfg")

class SimpleConfig(ConfigParser.ConfigParser):

    def __init__(self, cfg_path):
        self.cfg_path = cfg_path
        ConfigParser.ConfigParser.__init__(self)
        self.config_dict = None
        self.__parse_config()

    def __parse_config(self, reparse=False):
        if self.config_dict is None or reparse:
            self.read(self.cfg_path)
            self.config_dict = {}
            sections_list = self.sections()
            for section in sections_list:
                self.config_dict[section] = {}
                options_list = self.options(section)
                for option in options_list:
                    self.config_dict[section][option] = ConfigParser.ConfigParser.get(self, section, option)
        return self.config_dict

    def get(self, section, option, reparse=False):
        self.__parse_config(reparse)
        try:
            value = self.config_dict[section][option]
        except:
            if self.section_is_exists(section):
                value = "-undef-option"
            else:
                value = "-undef-section"
        return value

    def get_full(self, reparse=False):
        return self.__parse_config(reparse)

    def section_is_exists(self, section, reparse=False):
        self.__parse_config(reparse)
        if section in self.config_dict.keys():
            return True
        else:
            return False

    def add(self, section, option, value, reparse=True):
        if not self.section_is_exists(section, reparse):
            self.add_section(section)
        self.set(section, option, value)
        self.__sync_to_cfg_file()
        if "-undef-" not in self.get(section, option, value):
            return True
        else:
            return False

    def delconfig(self, section, option=None):
        if option is None:
            #delete full section
            try:
                self.remove_section(section)
                self.__sync_to_cfg_file()
                return True
            except:
                return False
        else:
            # delete one option
            try:
                self.remove_option(section, option)
                self.__sync_to_cfg_file()
                return True
            except:
                return False

    def __sync_to_cfg_file(self):
            cfg_file = open(self.cfg_path, 'w')
            self.write(cfg_file)
            cfg_file.close()
            self.__parse_config(reparse=True)

def init():
    cfg = SimpleConfig(cfg_path=config_path)
    return cfg

if __name__ == "__main__":
    cfg = init()
    print(cfg.get_full())
