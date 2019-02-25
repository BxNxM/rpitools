#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/../../colors.bash"

smart_patch="${MYDIR}/../../../tools/smart_patch_applier.bash"
local_orig_path="${MYDIR}/interfaces.orig"
local_patch_path="${MYDIR}/interfaces.patch"
etc_interfaces_path="/etc/network/interfaces"

echo -e "Patch $etc_interfaces_path"
exec "$smart_patch" "$etc_interfaces_path" "$local_patch_path"

