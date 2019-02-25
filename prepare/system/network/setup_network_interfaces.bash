#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/../../colors.bash"

smart_patch="${MYDIR}/../../../tools/smart_patch_applier.bash"
local_orig_path="${MYDIR}/interfaces.orig"
local_patch_path="${MYDIR}/interfaces.patch"
etc_interfaces_path="/etc/network/interfaces"

function _msg_() {
    local msg="$*"
    local title="${YELLOW}[network interfaces configure]${NC} "
    echo -e "$title$msg"
}

_msg_ "Setup network interfaces\nPatch $etc_interfaces_path"
stdout=$(exec "$smart_patch" "$etc_interfaces_path" "$local_patch_path")
if [[ "$stdout" != *"Skipping"* ]] || [[ "$stdout" != *"FAILED"* ]]
then
    _msg_ "Modification in progress."
    _msg_ "... restart networking service ..."
    #sudo systemctl restart networking.service
else
    _msg_ "Skipping, no modified."
fi
_msg_ "$etc_interfaces_path content:"
sudo cat "$etc_interfaces_path"
_msg_ "Interfaces and IPs"
ip a
