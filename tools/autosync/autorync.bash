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
echo -e "_____________________________________"
echo -e "AUTOSYNC EXECUTED: $(date)"

for config in "${sync_config_list[@]}"
do
    echo -e "SYNC based on: $config"
    log="$($autorync_core "$config")"
    exitcode="$?"
    if [ "$exitcode" -ne 0 ] || [ "${ARG_LIST[0]}" == "debug" ]
    then
        echo -e "$log" >> "$autorync_log_path"
        if [ "$exitcode" -eq 0 ]
        then
            echo -e "$config sync OK [$exitcode]"
        elif [ "$exitcode" -eq 245 ]
        then
            echo -e "$config sync already in PROGRESS [$exitcode]"
        else
            echo -e "$config sync FAILED [$exitcode]"
        fi
    else
        echo -e "$config sync OK [$exitcode]"
    fi
done

if [ "${#sync_config_list[@]}" -eq 0 ]
then
    echo -e "AUTOSYNC: modules are not available in $sync_configs_path"
fi
