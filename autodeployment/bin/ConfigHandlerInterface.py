#!/usr/bin/python
import argparse
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(myfolder, "../lib/")
sys.path.append(lib_path)
import ConfigHandler

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--section", help="select section")
parser.add_argument("-o", "--option", help="select option")

args = parser.parse_args()
section = args.section
option = args.option

if section is not None and option is not None:
    print("Do action")
