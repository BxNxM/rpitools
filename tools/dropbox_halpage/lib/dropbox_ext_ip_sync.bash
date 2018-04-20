#!/bin/bash

debugmsg=false
if [ "$1" == "-d" ]
then
    debugmsg=true
fi

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dropbox_uploader="${MYDIR}/Dropbox-Uploader/dropbox_uploader.sh"
local_cache_folder="${MYDIR}/local_cache/"
logfile="${MYDIR}/logs/extiphandler.log"

. ${MYDIR}/clone_n_configure.bash

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
uid_name="$($confighandler -s EXTIPHANDLER -o uid_name)"
uid_name_hum="${uid_name}_hum.md"
ssh_port="$($confighandler -s EXTIPHANDLER -o ssh_port)"
transmission_port="$($confighandler -s EXTIPHANDLER -o transmission_port)"
http_port="$($confighandler -s EXTIPHANDLER -o http_port)"
refresh_time="$($confighandler -s EXTIPHANDLER -o refresh_time)"
action="$($confighandler -s EXTIPHANDLER -o action)"

local_cache_myextaddr="${local_cache_folder}${uid_name}"
local_cache_myextaddr_hum="${local_cache_folder}${uid_name_hum}"

function debug_msg() {
    local msg="$@"
    if [ "$debugmsg" == "true" ]
    then
        echo -e "[$(date)]\t $msg"
    fi
        echo -e "[$(date)]\t $msg" >> "$logfile"
}

function GetIp {
    local ExtIP=$(curl http://ipecho.net/plain 2>/dev/null)
    valid_ext_ip=""

    if ! [[ "$ExtIP" == "" ]]                                                       #external ip not null
    then
        if [[ $ExtIP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]     #validing ip address (check dots...)
        then
            valid_ext_ip="$ExtIP"
        fi
    fi
    debug_msg "[1] Get IP address: |$valid_ext_ip|"
}

function safe_if_ext_ip_changed() {
    new_ip_is_found=0
    GetIp
    if [ "$valid_ext_ip" != "" ]
    then
        local myext_ip="$valid_ext_ip"

        # init myip file
        if [ ! -e "$local_cache_myextaddr" ]
        then
            init_needed=1
            echo "" > "$local_cache_myextaddr"
        else
            init_needed=0
        fi

        # save ip if new found
        is_changed="$(cat $local_cache_myextaddr | grep -v grep | grep $myext_ip)"
        if [[ "$is_changed" == "" ]] || [[ "$init_needed" -eq 1  ]]
        then
            info_ip_port="${myext_ip} ${ssh_port}"
            debug_msg "[2] Save new ip address: $myext_ip"
            echo -e "$info_ip_port" > "$local_cache_myextaddr"
            new_ip_is_found=1
        else
            debug_msg "[2]- $myext_ip - up to date"
        fi
    fi
}

function create_file_structure_if_not_exits() {
    local dropbox_folder_content=$("$dropbox_uploader" list)
    local halpage_folder="halpage"
    if [[ "$dropbox_folder_content" != *"$halpage_folder"* ]]
    then
        debug_msg "[3] Create $halpage_folder folder"
        root_folder_create=$("$dropbox_uploader" mkdir $halpage_folder)
        debug_msg "$root_folder_create"
    else
        debug_msg "[3] $halpage_folder folder already exists"
    fi

    dropbox_folder_content=$("$dropbox_uploader" list "$halpage_folder")
    if [ "$dropbox_folder_content" == *"servers"* ]
    then
        debug_msg "[3] Create servers folder"
        server_folder_create=$("$dropbox_uploader" mkdir ${halpage_folder}/servers)
    else
        debug_msg "[3] Servers folder already exists"
    fi
}

function upload_myip_file_if_new_ip_found() {
    local myip_dropbox_is_exits=$("$dropbox_uploader" list halpage/servers)
    if [ "$new_ip_is_found" -eq 1 ] || [[ "$myip_dropbox_is_exits" != *"$uid_name"* ]]
    then
        debug_msg "[4] Upload $uid_name file to dropbox folder servers/$uid_name"
        upload_new_ip=$("$dropbox_uploader" upload "$local_cache_myextaddr" "halpage/servers/$uid_name")
        debug_msg "$upload_new_ip"
    else
        debug_msg "[4] IP is not changed halpage/server/$uid_name"
    fi
}

function create_human_readabe_md_file() {
    text="## HALPAGE: $uid_name\n\n"
    text+="####$(date)\n\n"
    text+="***EXTERNAL IP ADDRESS:***\n\n"
    IFS=' ' read -r -a my_ext_ip <<< "$(cat $local_cache_myextaddr)"
    text+="\`\`\`${my_ext_ip[0]}\`\`\`\n\n"
    text+="***EXTERNAL SSH PORT:***\n\n"
    text+="\`\`\`${ssh_port}\`\`\`\n\n"
    text+="***TRANSMISSION ACCESS:***\n\n"
    text+="\`\`\`http://${my_ext_ip[0]}:${transmission_port}\`\`\`\n\n"
    text+="***HTTP ADDRESS:***\n\n"
    text+="\`\`\`http://${my_ext_ip[0]}:${http_port}\`\`\`"
    echo -e "$text" > "$local_cache_myextaddr_hum"
}


function upload_human_readable_page() {
    local myip_dropbox_is_exits=$("$dropbox_uploader" list halpage)
    if [ "$new_ip_is_found" -eq 1 ] || [[ "$myip_dropbox_is_exits" != *"$uid_name_hum"* ]]
    then
        create_human_readabe_md_file

        debug_msg "[5] Upload human readable halpage for: $uid_name_hum"
        upload_new_ip=$("$dropbox_uploader" upload "$local_cache_myextaddr_hum" "halpage/$uid_name_hum")
        debug_msg "$upload_new_ip"
    else
        debug_msg "[5] IP is not changed server/$uid_name_hum"
    fi
}

if [ "$action" == "True" ] || [ "$action" == "true" ]
then
    echo -e "[ DROPBOX HALPAGE ] service on"
    while true
    do
        safe_if_ext_ip_changed
        create_file_structure_if_not_exits
        upload_myip_file_if_new_ip_found
        upload_human_readable_page
        sleep "$refresh_time"
    done
elif [ "$action" == "False" ] || [ "$action" == "false" ]
then
    echo -e "[ DROPBOX HALPAGE ] service off"
    echo "" > /dev/null
else
    echo -e "[ DROPBOX HALPAGE ] service is not activated"
fi
