#!/bin/bash

pushd ../lib/
nohup python oled_gui_core.py > /dev/null &
popd
