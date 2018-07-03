#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../colors.bash"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
ssh_passed_state="$($confighandler -s SECURITY -o password_authentication)"
ssh_id_rsa_pub="$($confighandler -s SECURITY -o id_rsa_pub)"
sshd_config_path="/etc/ssh/sshd_config"
authorized_keys_path="/home/$USER/.ssh/authorized_keys"

_msg_title="SECURITY [SSH] SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${RED}[ $_msg_title ]${NC} - $msg"
}

function change_line() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        _msg_ "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        is_set="$(sudo cat "$where" | grep -v grep | grep "$to")"
        _msg_ "$is_set"
        if [ "$is_set" == "" ]
        then
            _msg_ "${GREEN}Set parameter (full line): $to  (from: $from) ${NC}"
            #sudo sed -i 's|'"${from}"'\c|'"${to}"'|g' "$where"
            sudo sed -i '/'"${from}"'/c\'"${to}"'' "$where"
        else
            _msg_ "${GREEN}Custom config line $to already set in $where ${NC}"
        fi
    fi
}

if [[ "$ssh_id_rsa_pub" == *"ssh-rsa"* ]]
then
    id_rsa_pubVALID=1
else
    _msg_ "id_rsa_pub ${RED}INVALID${NC}"
    id_rsa_pubVALID=0
fi

id_rsa_pub_is_set=$(cat "$authorized_keys_path" | grep "$ssh_id_rsa_pub")
if [[ "$id_rsa_pub_is_set" == "" ]] && [[ "$id_rsa_pubVALID" -eq 1 ]]
then
    _msg_ "id_rsa_pub from raspi_config setting up: $ssh_id_rsa_pub -> $authorized_keys_path"
    echo -e "$ssh_id_rsa_pub" >> "$authorized_keys_path"
else
    if [ "$id_rsa_pubVALID" -eq 1 ]
    then
        _msg_ "id_rsa_pub from raspi_config was already set: $ssh_id_rsa_pub"
    fi
fi

get_ssh_passwd_state_is_yes=$(cat $sshd_config_path | grep -v grep | grep "PasswordAuthentication yes")
get_ssh_passwd_state_is_no=$(cat $sshd_config_path | grep -v grep | grep "PasswordAuthentication no")
if [[ "$ssh_passed_state" == "True" ]] || [[ "$ssh_passed_state" == "true" ]]
then
    if [ "$get_ssh_passwd_state_is_yes" == "" ]
    then
        _msg_ "Set PasswordAuthentication yes ..."
        change_line "PasswordAuthentication no" "PasswordAuthentication yes" "$sshd_config_path"
        _msg_ "Restart ssh service: sudo systemctl restart ssh"
        sudo systemctl restart ssh
    else
        _msg_ "Already set [PasswordAuthentication yes]: $get_ssh_passwd_state_is_yes"
    fi
else
    if [ "$get_ssh_passwd_state_is_no" == "" ]
    then
        _msg_ "Set PasswordAuthentication no ..."
        change_line "PasswordAuthentication yes" "PasswordAuthentication no" "$sshd_config_path"
        _msg_ "Restart ssh service: sudo systemctl restart ssh"
        sudo systemctl restart ssh
    else
        _msg_ "Already set [PasswordAuthentication no]: $get_ssh_passwd_state_is_no"
    fi
fi
