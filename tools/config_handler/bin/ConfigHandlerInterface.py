#!/usr/bin/python
import argparse
import os
import sys

myfolder = os.path.dirname(os.path.abspath(__file__))

def rpienv_source():
    import subprocess
    if not os.path.exists(str(myfolder) + '/.rpienv'):
        print("[ ENV ERROR ] " + str(myfolder) + "/.rpienv path not exits!")
        sys.exit(1)
    command = ['bash', '-c', 'source ' + str(myfolder) + '/.rpienv -s && env']
    proc = subprocess.Popen(command, stdout = subprocess.PIPE)
    for line in proc.stdout:
        if type(line) is bytes:
            line = line.decode("utf-8")
        try:
            name = line.partition("=")[0]
            value = line.partition("=")[2]
            if type(value) is unicode:
                value = value.encode('ascii','ignore')
            value = value.rstrip()
            os.environ[name] = value
        except Exception as e:
            if "name 'unicode' is not defined" != str(e):
                print(e)
    proc.communicate()
rpienv_source()

lib_path = os.path.join(os.path.dirname(os.environ['CONFIGHANDLERPY']))
sys.path.append(lib_path)
import ConfigHandler

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--section", help="select section")
parser.add_argument("-o", "--option", help="select option")
parser.add_argument("-l", "--list",  action='store_true', help="list config dict")
parser.add_argument("-lf", "--list_formatted",  action='store_true', help="list config dict - formatted version")
parser.add_argument("-u", "--user_script",  action='store_true', help="set user script from config [bash]")
parser.add_argument("-v", "--validate",  action='store_true', help="validate configuration")

args = parser.parse_args()
section = args.section
option = args.option
listconfig = args.list
listconfig_formatted = args.list_formatted
validate = args.validate
user_script = args.user_script

if validate:
    cfg = ConfigHandler.init(validate_print=True)
else:
    cfg = ConfigHandler.init()

if section is not None and option is not None:
    print(cfg.get(section, option))
elif section is not None:
    section_json = cfg.get_full()[section]
    column_len_base = 0
    for opt, val in section_json.items():
        if column_len_base < len(opt):
            column_len_base = len(opt)
    print("[ {} ]".format(section))
    for opt, val in section_json.items():
        column_len = " " * (column_len_base+1-len(opt))
        print("\t{}:{}{}".format(opt, column_len, val))
    print("")

if listconfig:
    print(cfg.get_full())

if user_script:
    print(cfg.set_user_script())

if listconfig_formatted:
    print("=======================================")
    print("====  rpitools_config.cfg content  ====")
    print("=======================================")
    column_len_base = 0
    for section, opt_val in cfg.get_full().items():
        for opt, val in opt_val.items():
            if column_len_base < len(opt):
                column_len_base = len(opt)
    for section, opt_val in cfg.get_full().items():
        print("[ {} ]".format(section))
        for opt, val in opt_val.items():
            column_len = " " * (column_len_base+1-len(opt))
            print("\t{}:{}{}".format(opt, column_len, val))
        print("")
