#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

source "${TERMINALCOLORS}"

smart_patch="${SMARTPATCH}"
etc_interfaces_path="/etc/network/interfaces"
local_orig_path=""
local_patch_path=""

function _msg_() {
    local msg="$*"
    local title="${YELLOW}[network interfaces configure]${NC} "
    echo -e "$title$msg"
}

function select_patch_folder_by_eth0_exists() {
    local is_eth0_exists=$(ip link show | grep ": eth0:")
    local patch_folder=""
    if [ "$is_eth0_exists" != "" ]
    then
        patch_folder="eth0wlan0"
        _msg_ "eth0 interface is available, patch folder: $patch_folder"
    else
        patch_folder="wlan0"
        _msg_ "eth0 interface is NOT available, patch folder: $patch_folder"
    fi
    local_orig_path="${MYDIR}/${patch_folder}/interfaces.orig"
    local_patch_path="${MYDIR}/${patch_folder}/interfaces.patch"
    _msg_ "Patch file path: $local_patch_path"
}

_msg_ "Setup network interfaces\nPatch $etc_interfaces_path"
select_patch_folder_by_eth0_exists
stdout=$(exec "$smart_patch" "$etc_interfaces_path" "$local_patch_path")
_msg_ "SMART PATCH OUTPUT: $stdout"
if [[ "$stdout" == *"Skipping"* ]] || [[ "$stdout" == *"FAILED"* ]]
then
    _msg_ "Skipping, no modified."
else
    _msg_ "Modification in progress."
    _msg_ "... restart networking service ..."

    _msg_ "$etc_interfaces_path content:"
    sudo cat "$etc_interfaces_path"
    _msg_ "Interfaces and IPs"
    ip a

    _msg_ "Restart networking.service"
    sudo systemctl restart networking.service
fi
