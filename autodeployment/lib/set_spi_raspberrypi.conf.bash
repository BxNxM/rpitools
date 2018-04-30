#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"

_msg_title="SPI SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
}

conf_file_path="/etc/modules-load.d/raspberrypi.conf"
conf_file_path_moduls="/etc/modules"
if [ ! -e "$conf_file_path" ]
then
    _msg_ "Create file $conf_file_path (sudo echo \"\" > \"$conf_file_path\")"
    sudo /usr/bin/touch "$conf_file_path"
    sudo chmod 666 "$conf_file_path"
fi

function add_if_not_added() {
    local parameter="$1"
    local _conf_file_path="$2"
    local is_added=$(sudo grep -rnw "$_conf_file_path" -e "$parameter")
    if [ "$is_added" == "" ]
    then
        _msg_ "Add $parameter to $_conf_file_path"
        sudo echo "$parameter" >> "$_conf_file_path"
    fi
}

sudo chmod 666 "$conf_file_path"
sudo chmod 666 "$conf_file_path_moduls"
add_if_not_added "spi-bcm2708" "$conf_file_path"
add_if_not_added "spi-bcm2708" "$conf_file_path_moduls"
