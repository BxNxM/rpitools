#!/bin/bash

arg_len="$#"
arg="$1"
if [ "$arg_len" -eq 1 ]
then
    option="$arg"
fi

transmission_config_path="/etc/transmission-daemon/settings.json"
#---------------------------------------------------------------#
#--------------------- READ FILE TO ARRAY ----------------------#
#---------------------------------------------------------------#
function fileReader {                                           #FILE READER, READ FROM PATH TO ARRAY: search_line
    lineS=()

    if [ -e "$1" ]
    then
        while read line || [ -n "$line" ]
        do
            lineS+=($line)
        done < "$1"
    else
        echo -e "$1 NOT EXISTS!"
    fi
}
#fileReader template.txt
#after read ${lineS[x]

# prepare
function get_user_ips() {
    echo -e "GET USER EXTERNAL IPs"
    local action_new=0
    collected_user_ips=()
    get_users=($(ls -1 /home))
    echo -e "USERS: ${get_users[@]}"
    for ((users=0; users<${#get_users[@]}; users++))
    do
        user="${get_users[$users]}"
        echo -e "\tREAD /home/${user}/.myip"
        fileReader "/home/${user}/.myip"
        if [[ ${lineS[0]} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
        then
            is_new_ip="$(sudo cat $transmission_config_path | grep -v grep | grep ${lineS[0]})"
            if [ "$is_new_ip" == "" ]
            then
                echo -e "ACTION: New IP found! - ${lineS[0]}"
                action_new=1
            fi
            collected_user_ips+=("${lineS[0]} ")
        else
            echo -e ">>>>>>>>!!!!!!>>>>>>>INVALID USER IP ${lineS[0]}"
        fi
    done
    echo -e "user ips: ${#collected_user_ips[@]} db: ${collected_user_ips[@]}"
    if [ "$action_new" -eq 0 ]
    then
        collected_user_ips=()
    fi
    echo -e "new user ips: ${#collected_user_ips[@]} db: ${collected_user_ips[@]}"
}

function copy_transmission_config() {
    echo -e "COPY TRANSMISSION CONFIG COPY"
    new_version_path="${transmission_config_path}_new"
    echo -e "\tCOPY $transmission_config_path -->to--> $new_version_path"
    sudo cp $transmission_config_path $new_version_path
}

function edit_new_config() {
    echo -e "EDIT COPIED TRANSMISSION CONFIG"
    original='"rpc-whitelist": "127.0.0.1, 10.0.1.*, 192.168.0.*'
    new_line=("$original")
    for ((cnt=0; cnt<${#collected_user_ips[@]}; cnt++))
    do
        if [ $cnt -lt $((${#collected_user_ips[@]}-1)) ]
        then
            new_line+=(${collected_user_ips[$cnt]},)
        else
            new_line+=(${collected_user_ips[$cnt]})
        fi
    done
    newline_text="${new_line[@]}\","
    echo -e "original: $original"
    echo -e "newline: $newline_text"
    echo -e "\tCMD: sudo sed -i -e 's/${original}/${newline_text}/g' $new_version_path"
    sudo sed -i -e "s/${original}/${newline_text}/g" $new_version_path
}
#action

function action_stop_change_start() {
    echo -e "[!]> STOP TRANSMISSION"
    stop=$(sudo service transmission-daemon stop)
    if [ $? -eq 0 ]
    then
        if [ -e $new_version_path -a -e $transmission_config_path ]
        then
            echo -e "\t[!] MOVE NEW CONFIG: $new_version_path -->to--> $transmission_config_path"
            sudo mv -f $new_version_path $transmission_config_path
            echo -e "\t[!] CHANGE OWNER: $transmission_config_path"
            sudo chown -R debian-transmission $transmission_config_path
        else
            echo -e "FILE NOT EXIST: $new_version_path or $transmission_config_path"
        fi

        if [ -e $transmission_config_path ]
        then
            echo -e "[!]> START TRANSMISSION"
            start=$(sudo service transmission-daemon start)
            if [ $? -eq 0 ]
            then
                echo -e "\t[ OK ]> START TRANSMISSION"
            else
                echo -e "\t[ FAIL ]> START TRANSMISSION"
            fi
        else
            echo -e "FILE NOT EXIST: $transmission_config_path"
        fi
    else
        echo -e "FAILED TO STOP TRANSMISSION!"
    fi
}

while true
do
    get_user_ips
    if [ "${#collected_user_ips[@]}" -gt 0 ]
    then
        copy_transmission_config
        edit_new_config
        action_stop_change_start
    fi
    if [ -z "$option" ] && [ "$option" != "-l" ] || [ "$option" != "-loop" ]
    then
        break
    else
        echo -e "Run in loop..."
        sleep 2
    fi
done
