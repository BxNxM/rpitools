import ConfigParser
import os
import sys
import getpass
from Colors import Colors
myfolder = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(myfolder, "../config/rpitools_config.cfg")
template_config_path = os.path.join(myfolder, "../config/rpitools_config_template.cfg")
USER = getpass.getuser()
storage_path_structure_path = os.path.join(myfolder, "../../cache/storage_path_structure")

class SimpleConfig(ConfigParser.ConfigParser):

    def __init__(self, cfg_path, magic_var_resolve=True):
        self.cfg_path = cfg_path
        ConfigParser.ConfigParser.__init__(self, allow_no_value=True)
        self.config_dict = None
        self.magic_var_resolve = magic_var_resolve
        self.__parse_config()

    def __parse_config(self, reparse=False):
        global USER
        if self.config_dict is None or reparse:
            self.read(self.cfg_path)
            self.config_dict = {}
            sections_list = self.sections()
            for section in sections_list:
                self.config_dict[section] = {}
                options_list = self.options(section)
                for option in options_list:
                    if self.magic_var_resolve:
                        parameter = self.__replace_magic_variables(ConfigParser.ConfigParser.get(self, section, option))
                    else:
                        parameter = ConfigParser.ConfigParser.get(self, section, option)
                    self.config_dict[section][option] = parameter
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
        if "-undef-" not in self.get(section, option):
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


    def set_user_script(self):
        state = "Unknown"
        is_activated = self.get("USER_SPACE", "activate", reparse=True)
        if "-undef-section" not in is_activated and is_activated.lower() == "true":
            path = self.get("USER_SPACE", "path", reparse=False)
            script = self.get("USER_SPACE", "script", reparse=False)
            with open(path, 'w') as f:
                f.write(script)
            state = "Write user script was successful."
        elif "-undef-section" not in is_activated and is_activated.lower() != "true":
            state = "User script was NOT activated."
        else:
            state = "USER_SPACE not exists in config."
        return state

    def __replace_magic_variables(self, parameter):
        global storage_path_structure_path
        global USER

        # Set username - runtime parameter "magic variable"
        parameter = parameter.replace("$USER", USER)
        parameter = parameter.replace("~/", "/home/{}".format(USER))
        parameter = parameter.replace("$HOME", "/home/{}".format(USER))

        # Set storage_path_structure parameters
        if os.path.exists(storage_path_structure_path):
            with open(storage_path_structure_path, 'r') as f:
                storage_path_config_raw = f.read()
            storage_path_config_lines = storage_path_config_raw.split('\n')
            for line in storage_path_config_lines:
                # remove comment
                if line[0] != '#':
                    #split by key=value
                    key, value = line.split('=')
                    if "$"+str(key) in parameter:
                        parameter = parameter.replace("$"+str(key), value)
        return parameter

def validate_configs_based_on_template_printout(msg, is_active=True):
    if is_active:
        print(msg)

def validate_configs_based_on_template(custom_cfg_obj, cfg_template_path=template_config_path, print_is_active=False):
    difference_cnt = 0
    cfg_tmp = SimpleConfig(cfg_path=template_config_path)
    custom_all_dict = custom_cfg_obj.get_full()
    template_all_dict = cfg_tmp.get_full()

    validate_configs_based_on_template_printout("VALIDATE CUSTOM (USER) CONFIG FILE: {} WITH {}"\
                                                .format(config_path, template_config_path), is_active=print_is_active)
    for key, value in template_all_dict.items():
        # check sections - user (custom) config based on template config
        if key in custom_all_dict.keys():
            validate_configs_based_on_template_printout(str(key) + " - section exists - " + Colors.GREEN\
                                                        + "OK" + Colors.NC, is_active=print_is_active)
        else:
            validate_configs_based_on_template_printout(str(key) + " - section not exits - " + Colors.RED\
                                                        + "MISSING" + Colors.NC, is_active=print_is_active)
            difference_cnt += 1
        # check options user (custom) config based on template config
        for key_in, value_in in value.items():
            try:
                if str(key_in) in str(custom_all_dict[key]):
                    validate_configs_based_on_template_printout("\t" + str(key_in) + " - key exists - " + Colors.GREEN\
                                                                + "OK" + Colors.NC, is_active=print_is_active)
                else:
                    validate_configs_based_on_template_printout("\t" + str(key_in) + " - key not exits - " + Colors.RED\
                                                               + "MISSING" + Colors.NC, is_active=print_is_active)
                    difference_cnt += 1
            except Exception as e:
                difference_cnt += 1
    if difference_cnt == 0:
        sync_rpitools_version(custom_cfg_obj, cfg_tmp, is_active=print_is_active)
        return True
    else:
        return False

def sync_rpitools_version(custom_cfg_obj, template_config_obj, is_active):
    global config_path, template_config_path
    option = "GENERAL"
    section = "rpitools_version"
    try:
        version = float(template_config_obj.get(option, section))
        version_actual = float(custom_cfg_obj.get(option, section))
        if version != version_actual:
            validate_configs_based_on_template_printout("Update rpitools config version from {} to {}".format(version_actual, version), is_active)
            if not custom_cfg_obj.add(option, section, str(version)):
                print("Fail to update rpitools version: " + str(version_actual) + " -> " + str(version))
            reformat_custom_config_based_on_template(config_path, template_config_path, is_active)
    except Exception as e:
        print("Verison number update failed: " + str(e))

def reformat_custom_config_based_on_template(config_path, template_config_path, is_active):
    print("REGENERATE RPITOOLS CONFIG FILE STRUCTURE WITH COMMENTS")
    error = 0
    try:
        print("\t[1] Copy template and fill with custom values")
        import shutil
        template_config_path_swp = template_config_path + ".swp"
        shutil.copyfile(template_config_path, template_config_path_swp)

        custom_config_obj = SimpleConfig(cfg_path = config_path, magic_var_resolve=False)
        template_conf_swp_obj = SimpleConfig(cfg_path = template_config_path_swp, magic_var_resolve=False)
        custom_full = custom_config_obj.get_full()

        # fill template swp with custom values
        for section, option_value in custom_full.items():
            for option, value in option_value.items():
                template_conf_swp_obj.add(section, option, value, reparse=False)
                validate_configs_based_on_template_printout("\t\tSet {}:{}={}".format(section, option, value), is_active)
    except Exception as e:
        print("Regenerate config file failed: " + str(e))
        error = 1

    try:
        if error == 0:
            print("\t[2] Backup previous rpitools config, and write out the new :)")
            # create custom config backup
            shutil.copyfile(config_path, config_path + ".bak")
            # override custom config file with reformatted version
            shutil.move(template_config_path_swp, config_path)
    except Exception as e:
        print("Overwrite custom config file failed, check {} config backup, error: {}".format(config_path, config_path + ".bak", e))
        error = 1

    if error == 0:
        try:
            print("\t[3] Merge comments from template to the new custom config")
            final_formatted_config_with_comments = ""
            with open(template_config_path, 'r') as f:
                template_config_content = f.read()
                template_config_content_lines = template_config_content.split("\n")
            with open(config_path, 'r') as f:
                custom_config_content = f.read()
                custom_config_content_lines = custom_config_content.split("\n")

            comment_lines_index_cnt = 0
            end_comment_block = True
            for index, template_line in enumerate(template_config_content_lines):
                if len(template_line) > 0 and template_line[0] == ";":
                    final_formatted_config_with_comments += template_line + "\n"
                    end_comment_block = False
                    validate_configs_based_on_template_printout("{}[TEMP][ix:{}] {}{}".format(Colors.LIGHT_BLUE, comment_lines_index_cnt, template_line,\
                                                                Colors.NC), is_active)
                    comment_lines_index_cnt += 1
                else:
                    end_comment_block = True
                if end_comment_block:
                    if len(custom_config_content_lines) > index - comment_lines_index_cnt:
                        validate_configs_based_on_template_printout("{}[CUST][ix:{}] {}{}".format(Colors.LIGHT_GREEN, index - comment_lines_index_cnt,\
                               custom_config_content_lines[index - comment_lines_index_cnt], Colors.NC), is_active)
                        final_formatted_config_with_comments += custom_config_content_lines[index - comment_lines_index_cnt] + "\n"
            # Custom config file user space script longer then default, write the rest out
            if len(custom_config_content_lines) > index - comment_lines_index_cnt:
                for newindex in range(index - comment_lines_index_cnt, len(custom_config_content_lines) -1):
                    validate_configs_based_on_template_printout("{}[CUST][ix:{}] {}{}".format(Colors.LIGHT_GREEN, newindex, custom_config_content_lines[newindex],\
                                                                Colors.NC), is_active)
                    final_formatted_config_with_comments += custom_config_content_lines[newindex] + "\n"

            # Write merged config to rpitools config
            with open(config_path, 'w') as f:
                f.write(final_formatted_config_with_comments)
        except Exception as e:
            print("Merge comments to custom rpitools template failed: " + str(e))

def init(validate_print=False):
    cfg = SimpleConfig(cfg_path=config_path)
    if validate_configs_based_on_template(cfg, print_is_active=validate_print):
        return cfg
    else:
        print("[ WARNING ] - CUSTOM CONFIG FILE IS INVALID! : " + str(config_path))
        sys.exit(1)

if __name__ == "__main__":
    cfg = init(validate_print=True)
    print(cfg.get_full())
