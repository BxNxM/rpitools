#!/bin/bash

args_len="$#"
arg="$1"
if [  "$args_len" -eq 1 ] && [ "$arg" != "-h" ] && [ "$arg" != "--help" ]
then
    server_connection_input="$arg"
else
    echo -e "This script needs one parameter, the server you want to copy your key:\nexample: pi@raspberrypi.local"
    exit 1
fi

function check_id_rsa_pub_exists(){
    if [ ! -e "/home/$USER/.ssh/id_rsa.pub" ]
    then
        echo -e "You have to create id_rsa.pub\nssh-keygen"
        ssh-keygen
    else
        echo -e "/home/$USER/.ssh/id_rsa.pub already exists"
   fi
    echo -e ""
}

function get_ssh_key() {
    echo -e "cat /home/$USER/.ssh/id_rsa.pub"
    id_rsa_pub="$(cat /home/$USER/.ssh/id_rsa.pub)"
    echo -e "$id_rsa_pub"
    echo -e ""
}

function copy_to_the_server() {
    local server_connection="$1"           # pi@raspberrypi.local
    echo -e 'ssh '"$server_connection"' "cat ~/.ssh/authorized_keys | grep '"'${id_rsa_pub}'"'"'
    is_added=$(ssh "$server_connection" "cat ~/.ssh/authorized_keys | grep '${id_rsa_pub}'")
    if [ "$is_added" == "" ]
    then
        echo -e "$server_connection" "echo -e $id_rsa_pub >> ~/.ssh/authorized_keys"
        ssh "$server_connection" "echo -e $id_rsa_pub >> ~/.ssh/authorized_keys"
        if [ "$?" -eq 0 ]
        then
            echo -e "SUCCESS"
        else
            echo -e FAIL""
        fi
    else
        echo -e "Your key is already added"
    fi
    echo -e ""
}

check_id_rsa_pub_exists
get_ssh_key
copy_to_the_server "$server_connection_input"
