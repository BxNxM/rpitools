#!/bin/bash

ARG_LIST=($@)

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
sync_configs_path="${MYDIR}/sync_configs/"
autorync_core="${MYDIR}/autorync_core.bash"
autorync_log_path="${MYDIR}/sync.log"

sync_config_list=($(find "$sync_configs_path" -type f -iname "*.sync" | grep -v "template"))
echo -e "${sync_config_list[*]}"
for config in ${sync_config_list[@]}
do
    echo -e "SYNC based on: $config"
    log="$($autorync_core "$config")"
    echo -e "$log" >> "$autorync_log_path"
done

