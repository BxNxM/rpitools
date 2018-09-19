#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"

source "${MYDIR_}/message.bash"
_msg_title="I2C SETUP"

conf_file_path="/etc/modules-load.d/raspberrypi.conf"
if [ ! -e "$conf_file_path" ]
then
    _msg_ "Create file $conf_file_path (sudo echo \"\" > \"$conf_file_path\")"
    sudo /usr/bin/touch "$conf_file_path"
    sudo chmod 666 "$conf_file_path"
fi

function add_if_not_added() {
    local parameter="$1"
    local is_added=$(sudo grep -rnw "$conf_file_path" -e "$parameter")
    if [ "$is_added" == "" ]
    then
        _msg_ "Add $parameter to $conf_file_path"
        sudo echo "$parameter" >> "$conf_file_path"
    fi
}

sudo chmod 666 "$conf_file_path"
add_if_not_added "i2c-bcm2708"
add_if_not_added "i2c-dev"
