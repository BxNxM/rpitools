#!/bin/bash

function safe_lounch() {
    ps=$(ps aux | grep -v grep | grep "oled_gui_core.py")
    if [ "$ps" == "" ]
    then
        lounch
    else
        echo -e "already run"
    fi
}

function lounch() {
    MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    pushd "${MYDIR}/../lib"
    nohup python oled_gui_core.py > /dev/null &
    popd
}

safe_lounch

