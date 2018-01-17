#!/bin/bash

# more info about conky: https://www.novaspirit.com/2017/02/23/desktop-widget-raspberry-pi-using-conky/
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -e ~/.conkyrc ]
then
    echo -e "Copy conly configuration: ${MYDIR}/.conkyrc -> ~/.conkyrc"
    cp "${MYDIR}/.conkyrc" ~/.conkyrc
else
    echo -e "~/.conkyrc is already set"
fi


is_run=$(ps aux | grep -v grep | grep "conky")
if [ "$is_run" == "" ]
then
    echo -e "Run conky"
    (conky) &
    exit 0
else
    echo -e "Conky is already run"
fi
