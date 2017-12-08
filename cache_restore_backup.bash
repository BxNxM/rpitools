#!/bin/bash

arg_len=$#
arg_list=$@

backup_path=~/.rpitools_bckp/

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ cache backup/retore ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ cache backup/retore ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

# check we are sourced up
if [ -z "$REPOROOT" ]
then
    message "Please ${RED}source rpitools/setup${NC} before use these script!"
    exit 1
fi

if [ "$arg_len" == 1 ]
then
    if [ "${arg_list[0]}" == "backup" ]
    then
        echo -e "Create cache backup"
        if [ ! -d "$backup_path" ]
        then
            mkdir "$backup_path"
        fi
        cp -r "${REPOROOT}/cache" "$backup_path"

    elif [ "${arg_list[0]}" == "restore" ]
    then
        echo -e "Restore backup"
        if [ -e "${backup_path}/cache" ]
        then
            cp -r "${backup_path}/cache" "${REPOROOT}"
        else
            echo -e "Backup not found! ${backup_path}/cache"
        fi
    else
        "Invalid input ${arg_list[0]}\nTry backup/restore"
    fi
else
    echo -e "AVAIBLE INPUTS: backup/restore\nthese are cache saving options for easier repo update"
fi
