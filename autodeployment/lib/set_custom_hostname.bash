#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.custom_hostname_is_set"
source "${MYDIR_}/../../prepare/colors.bash"

hostname_path="/etc/hostname"
hosts_path="/etc/hosts"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
custom_host_name="$($confighandler -s GENERAL -o custom_hostname)"

source "${MYDIR_}/message.bash"
_msg_title="CUSTOM HOSTNAME SETUP"

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

function hostname_change_is_needed() {
    change_is_required=0
    if [ -f "$hostname_path" ]
    then
        if [ "$(cat $hostname_path | grep $custom_host_name)" == "" ]
        then
            change_is_required=1
        fi
    else
            change_is_required=1
    fi
}

hostname_change_is_needed
if [ "$change_is_required" -eq 1 ]
then
    # get previous hostname (default hostname) if $hostname_path exists
    if [ -f "$hostname_path" ]
    then
        default_hostname="$(cat $hostname_path)"
    else
        default_hostname=""
    fi
    # if previous or default hostanme not available set it to factory default: raspberrypi
    if [ "$default_hostname" == "" ]
    then
        default_hostname="raspberrypi"
    fi

    _msg_ "${YELLOW}SET HOSTNAME: $custom_host_name (from: $default_hostname)${NC}"
    set_custom_host "$default_hostname" "$hostname_path"
    set_custom_host "$default_hostname" "$hosts_path"
    echo -e "" > "$CACHE_PATH_is_set"

    _msg_ "NEW HOSTNAME WAS SET RESTART SYSTEM"
    sudo reboot
else
    _msg_ "Machine hostname is already set in $hostname_path -> $custom_host_name!"
fi
