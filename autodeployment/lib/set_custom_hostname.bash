#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.custom_hostname_is_set"
source "${MYDIR_}/../../prepare/colors.bash"

hostname_path="/etc/hostname"
hosts_path="/etc/hosts"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
custom_host_name="$($confighandler -s RPI_MODEL -o custom_hostname)"

_msg_title="CUSTOM HOSTNAME SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
}

function set_custom_host() {
    local from="$1"
    local where="$2"
    if [ ! -z "$from" ]
    then
        _msg_ "cat $where | grep -v grep | grep $custom_host_name\nis_set: $is_set"
        is_set="$(cat "$where" | grep -v grep | grep "$custom_host_name")"
        _msg_ "$is_set"
        if [ "$is_set" == "" ]
        then
            _msg_ "${GREEN}Set custom hostname: $custom_host_name ${NC}"
            sudo sed -i 's|'"${from}"'|'"${custom_host_name}"'|g' "$where"
        else
            _msg_ "${GREEN}Custom host name $custom_host_name already set in $where ${NC}"
        fi
    fi
}

if [ ! -e "$CACHE_PATH_is_set" ]
then
    default_hostname="raspberrypi"
    _msg_ "${YELLOW}SET HOSTNAME: $custom_host_name (from: $default_hostname)${NC}"
    set_custom_host "$default_hostname" "$hostname_path"
    set_custom_host "$default_hostname" "$hosts_path"
    echo -e "" > "$CACHE_PATH_is_set"
else
    _msg_ "Machine hostname is already set! -> $CACHE_PATH_is_set exists"
fi
