#!/bin/bash

#https://github.com/andreafabrizi/Dropbox-Uploader
lounch_mode="$1"
if [ ! -z "$lounch_mode" ] && [ "$lounch_mode" == "-s" ]
then
    lounch_mode=1
else
    lounch_mode=0
fi

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
is_running="$(ps aux | grep -v grep | grep 'dropbox_ext_ip_sync.bash')"
if [ "$is_running" == "" ]
then
    if [ "$lounch_mode" == 0 ]
    then
        ("${MYDIR}/../lib/dropbox_ext_ip_sync.bash" &)
    else
        . ${MYDIR}/../lib/dropbox_ext_ip_sync.bash
    fi
else
    echo -e "[ DROPBOX HALPAGE ] already running"
fi


