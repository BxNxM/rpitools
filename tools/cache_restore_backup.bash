#!/bin/bash

arg_len="$#"
arg_list=($@)
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

        if [ -d "${REPOROOT}/tools/dropbox_halpage/lib/Dropbox-Uploader" ]
        then
            # Dropbox-Uploader lib
            echo -e "\tbackup: ${REPOROOT}/tools/dropbox_halpage/lib/Dropbox-Uploader -> $backup_path"
            sudo cp -r "${REPOROOT}/tools/dropbox_halpage/lib/Dropbox-Uploader" "$backup_path"
        else
            echo -e "\t${REPOROOT}/tools/dropbox_halpage/lib/Dropbox-Uploader not present in the system."
        fi

        if [ -d "${REPOROOT}/autodeployment/lib/retropie/RetroPie-Setup" ]
        then
            # Retropie setup
            echo -e "\tbackup: ${REPOROOT}/autodeployment/lib/retropie/RetroPie-Setup" "$backup_path"
            sudo cp -r "${REPOROOT}/autodeployment/lib/retropie/RetroPie-Setup" "$backup_path"
        else
            echo -e "\t${REPOROOT}/autodeployment/lib/retropie/RetroPie-Setup not present in the system."
        fi

        if [ -e "${REPOROOT}/tools/gotop/gotop" ]
        then
            # Gotop script
            echo -e "\tbackup: ${REPOROOT}/tools/gotop/gotop" "$backup_path"
            sudo cp -r "${REPOROOT}/tools/gotop/gotop" "$backup_path"
        else
            echo -e "\t${REPOROOT}/tools/gotop/gotop not present in the system."
        fi

        if [ -d "${REPOROOT}/tools/autosync/sync_configs/" ]
        then
            # autosync sync_configs
            echo -e "\tbackup: ${REPOROOT}/tools/autosync/sync_configs/ -> $backup_path"
            sudo bash -c "cp -ra "${REPOROOT}/tools/autosync/sync_configs/" "$backup_path""
            cache_exitcode="$?"
        else
             echo -e "${REPOROOT}/tools/autosync/sync_configs/not present in the system."
        fi

        # cache
        echo -e "\tbackup: ${REPOROOT}/cache -> $backup_path"
        sudo bash -c "cp -ra "${REPOROOT}/cache" "$backup_path""
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

            if [ -d "${backup_path}/Dropbox-Uploader" ]
            then
                # Dropbox-Uploader lib
                echo -e "\trestore: ${backup_path}/Dropbox-Uploader -> ${REPOROOT}/tools/dropbox_halpage/lib/"
                sudo cp -r "${backup_path}/Dropbox-Uploader" "${REPOROOT}/tools/dropbox_halpage/lib/"
            else
                echo -e "restore: ${backup_path}/Dropbox-Uploader not present in the system."
            fi

            if [ -d "${backup_path}/RetroPie-Setup" ]
            then
                # Retropie setup
                echo -e "\trestore: ${backup_path}/RetroPie-Setup -> ${REPOROOT}/autodeployment/lib/retropie/"
                sudo cp -r "${backup_path}/RetroPie-Setup" "${REPOROOT}/autodeployment/lib/retropie/"
            else
                echo -e "\trestore: ${backup_path}/RetroPie-Setup not present in the system."
            fi

            if [ -e "${backup_path}/gotop" ]
            then
                # gotoop script
                echo -e "\trestore: ${backup_path}/gotop -> ${REPOROOT}/tools/gotop/"
                sudo cp -r "${backup_path}/gotop" "${REPOROOT}/tools/gotop/"
            else
                echo -e "\trestore: ${backup_path}/gotop not present in the system."
            fi

            if [ -d "${backup_path}/sync_configs" ]
            then
                # autosync sync_configs
                echo -e "\trestore: ${backup_path}/sync_configs/ -> ${REPOROOT}/tools/autosync/"
                sudo bash -c "cp -ra "${backup_path}/sync_configs/" "${REPOROOT}/tools/autosync/""
                cache_exitcode="$?"
            else
                echo -e "\trestore: ${backup_path}/sync_configs not present in the system."
            fi

            # cache
            echo -e "\trestore: ${backup_path}/cache -> ${REPOROOT}"
            sudo bash -c "cp -ra "${backup_path}/cache" "${REPOROOT}""
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
