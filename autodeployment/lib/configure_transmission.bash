#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.transmission_configure_is_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

transmission_conf_path="/etc/transmission-daemon/settings.json"
download_path="$($confighandler -s TRANSMISSION -o download_path)"
incomp_download_path="$($confighandler -s TRANSMISSION -o incomp_download_path)"
username="$($confighandler -s TRANSMISSION -o username)"
passwd="$($confighandler -s TRANSMISSION -o passwd)"

function change_parameter() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        echo -e "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        is_set="$(sudo cat "$where" | grep -v grep | grep "$to")"
        echo -e "$is_set"
        if [ "$is_set" == "" ]
        then
            echo -e "${GREEN}Set parameter: $to  (from: $from) ${NC}"
            sudo sed -i 's|'"${from}"'|'"${to}"'|g' "$where"
        else
            echo -e "${GREEN}Custom parameter $to already set in $where ${NC}"
        fi
    fi
}

function change_line() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        echo -e "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        is_set="$(sudo cat "$where" | grep -v grep | grep "$to")"
        echo -e "$is_set"
        if [ "$is_set" == "" ]
        then
            echo -e "${GREEN}Set parameter (full line): $to  (from: $from) ${NC}"
            #sudo sed -i 's|'"${from}"'\c|'"${to}"'|g' "$where"
            sudo sed -i '/'"${from}"'/c\'"${to}"'' "$where"
        else
            echo -e "${GREEN}Custom config line $to already set in $where ${NC}"
        fi
    fi
}

if [ ! -e "$CACHE_PATH_is_set" ]
then
    # create downloads dir
    if [ ! -e "${download_path}" ]
    then
        echo -e "Create download dir: ${download_path}"
        mkdir -p "${download_path}"
    else
        echo -e "Downloads dir exists: ${download_path}"
    fi

    # create incomplete downloads dir
    if [ ! -e "${incomp_download_path}" ]
    then
        echo -e "Create incomplete download dir: ${incomp_download_path}"
        mkdir -p "${incomp_download_path}"
    else
        echo -e "Incomplete downloads dir exists: ${incomp_download_path}"
    fi

    echo -e "SET DOWNLOADS FOLDER: $download_path IN: $transmission_conf_path"
    #change_parameter "/var/lib/transmission-daemon/downloads" "$download_path" "$transmission_conf_path"
    change_line "download-dir" "    \"download-dir\": \"${download_path}\"," "$transmission_conf_path"

    echo -e "SET INCOMP DOWNLOADS FOLDER: $incomp_download_path IN: $transmission_conf_path"
    #change_parameter "/var/lib/transmission-daemon/Downloads" "$incomp_download_path" "$transmission_conf_path"
    change_line "incomplete-dir" "    \"incomplete-dir\": \"$incomp_download_path\"," "$transmission_conf_path"
    change_parameter "\"incomplete-dir-enabled\": false" "\"incomplete-dir-enabled\": true" "$transmission_conf_path"

    echo -e "SET USERNAME TO: $username (FROM transmission)"
    #change_parameter "\"rpc-username\": \"transmission\"" "\"rpc-username\": \"${username}\"" "$transmission_conf_path"
    change_line "rpc-username" "    \"rpc-username\": \"${username}\"," "$transmission_conf_path"

    echo -e "SET PASSWORD TO: $passwd"
    change_line "rpc-password" "    \"rpc-password\": \""$passwd"\"," "$transmission_conf_path"

    echo "" > "$CACHE_PATH_is_set"
else
    echo -e "Transmission is already set: $CACHE_PATH_is_set is exists"
fi


