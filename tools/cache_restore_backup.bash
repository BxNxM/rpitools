#!/bin/bash

arg_len=$#
arg_list=$@
mypath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPOROOT="$(dirname $mypath)"

backup_path=~/.rpitools_bckp/

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

if [ "$arg_len" == 1 ]
then
    if [ "${arg_list[0]}" == "backup" ]
    then
        echo -e "Create cache backup"
        if [ ! -d "$backup_path" ]
        then
            mkdir "$backup_path"
        fi
        # backup cache and adafruit library
        # adafruit lib
        echo -e "\tbackup: ${REPOROOT}/gpio/Adafruit_Python_SSD1306 -> $backup_path"
        sudo cp -r "${REPOROOT}/gpio/Adafruit_Python_SSD1306" "$backup_path"

        # Dropbox-Uploader lib
        echo -e "\tbackup: ${REPOROOT}/tools/dropbox_halpage/lib/Dropbox-Uploader -> $backup_path"
        sudo cp -r "${REPOROOT}/tools/dropbox_halpage/lib/Dropbox-Uploader" "$backup_path"

        # cache
        echo -e "\tbackup: ${REPOROOT}/cache -> $backup_path"
        cp -r "${REPOROOT}/cache" "$backup_path"
        cache_exitcode="$?"

        # backup config
        echo -e "\tbackup: ${REPOROOT}/autodeployment/config/rpitools_config.cfg -> $backup_path"
        cp "${REPOROOT}/autodeployment/config/rpitools_config.cfg" "$backup_path"
        config_copy_exitcode="$?"
        if [ "$cache_exitcode" -eq 0 ] && [ "$config_copy_exitcode" -eq 0 ]
        then
            echo -e "Create backup SUCCESS"
        else
            echo -e "Create backup FAIL"
        fi

    elif [ "${arg_list[0]}" == "restore" ]
    then
        echo -e "Restore backup"
        if [ -e "${backup_path}/cache" ]
        then
            # restore cache and Adafruit library
            # adafruit lib
            echo -e "\trestore: ${backup_path}/cache/Adafruit_Python_SSD1306 -> ${REPOROOT}/gpio/"
            sudo cp -r "${backup_path}/Adafruit_Python_SSD1306" "${REPOROOT}/gpio/"

            # Dropbox-Uploader lib
            echo -e "\trestore: ${backup_path}/Dropbox-Uploader -> ${REPOROOT}/tools/dropbox_halpage/lib/"
            sudo cp -r "${backup_path}/Dropbox-Uploader" "${REPOROOT}/tools/dropbox_halpage/lib/"

            # cache
            echo -e "\trestore: ${backup_path}/cache -> ${REPOROOT}"
            cp -r "${backup_path}/cache" "${REPOROOT}"
            cache_exitcode="$?"

            # restore config
            echo -e "\trestore: ${backup_path}/rpitools_config.cfg -> ${REPOROOT}/autodeployment/config/"
            cp "${backup_path}/rpitools_config.cfg" "${REPOROOT}/autodeployment/config/"
            config_copy_exitcode="$?"
            if [ "$cache_exitcode" -eq 0 ] && [ "$config_copy_exitcode" -eq 0 ]
            then
                echo -e "Restore backup SUCCESS"
            else
                echo -e "Restore backup FAIL"
            fi
        else
            echo -e "Backup not found! ${backup_path}/cache"
        fi
    else
        "Invalid input ${arg_list[0]}\nTry backup/restore"
    fi
else
    echo -e "AVAIBLE INPUTS: backup/restore\nthese are cache saving options for easier repo update"
fi
