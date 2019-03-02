#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/../../colors.bash"

smart_patch="${MYDIR}/../../../tools/smart_patch_applier.bash"
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
