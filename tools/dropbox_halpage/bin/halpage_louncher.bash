#!/bin/bash

#https://github.com/andreafabrizi/Dropbox-Uploader

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
is_running="$(ps aux | grep -v grep | grep 'dropbox_ext_ip_sync.bash')"
if [ "$is_running" == "" ]
then
    ("${MYDIR}/../lib/dropbox_ext_ip_sync.bash" &)
else
    echo -e "[ DROPBOX HALPAGE ] already running"
fi


