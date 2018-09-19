#!/bin/bash

arg_len="$#"
arg_list=("$@")

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../colors.bash"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
ssh_passed_state="$($confighandler -s SECURITY -o password_authentication)"
ssh_id_rsa_pub="$($confighandler -s SECURITY -o id_rsa_pub)"
sshd_config_path="/etc/ssh/sshd_config"
authorized_keys_path="/home/$USER/.ssh/authorized_keys"
default_id_rsa_pub_value_in_conf="write_you_id_rsa_pub_here"
rpi_config_path="/home/$USER/rpitools/autodeployment/config/rpitools_config.cfg"
cache_path="/home/$USER/rpitools/cache/"
repo_conf_restore_backup="/home/$USER/rpitools/tools/cache_restore_backup.bash"

_msg_title="SECURITY [SSH] SETUP"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${RED}[ $_msg_title ]${NC} - $msg"
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

function change_parameter() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        is_set="$(sudo cat "$where" | grep -v grep | grep "$to")"
        _msg_ "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        _msg_ "$is_set"
        if [ "$is_set" == "" ]
        then
            _msg_ "${GREEN}Set parameter: $to  (from: $from) ${NC}"
            sudo sed -i 's|'"${from}"'|'"${to}"'|g' "$where"
        else
            _msg_ "${GREEN}Custom parameter $to already set in $where ${NC}"
        fi
    fi
}

function save_authorized_keys_first_key_to_rpi_config() {
    local first_id_rsa_pub="$(head -n 1 $authorized_keys_path)"
    if [[ "$first_id_rsa_pub" == *"ssh-rsa"* ]]
    then
        _msg_ "id_rsa_pub exists in $authorized_keys_path, SAVE it to rpi_config"
        change_parameter "id_rsa_pub=write_you_id_rsa_pub_here" "id_rsa_pub=${first_id_rsa_pub}" "$rpi_config_path"

        _msg_ "Validate config after modifications"
        echo -e "$($confighandler -v)"
        if [ "$?" -eq 0 ]
        then
            _msg_ "Save modifications."
            _msg_ "$($repo_conf_restore_backup backup)"
            id_rsa_pubVALID=1
        else
            _msg_ "Save id_rsa.pub first key to $rpi_config_path went failed! restoring previous one."
            _msg_ "$($repo_conf_restore_backup restore)"
            id_rsa_pubVALID=0
        fi
    else
        _msg_ "id_rsa_pub not exists in $authorized_keys_path"
        id_rsa_pubVALID=0
    fi
}

function configure_ufw() {
    local PORT_LIST=()
    local PORT=""
    local APP_LIST=()
    local APP=""
    local bckp_msg_title="$_msg_title"
    local whitelist=(137 138)                   # samba ("passive ports")
    local black_list=()                         # TODO
    _msg_title="SECURITY [ufw] SETUP"

    _msg_ "Show used ports: sudo netstat -tulpn"
    active_ports_apps_list=($(sudo netstat -tulpn | grep -i LISTEN | awk '{print $4 "\t" $7}'))

    for ((portsapps_i=0; portsapps_i<"${#active_ports_apps_list[@]}"; portsapps_i+=2))
    do
        IFS=':' read -ra PORT_LIST <<< "${active_ports_apps_list[$portsapps_i]}"
        PORT_LIST=(${PORT_LIST[*]})
        PORT="${PORT_LIST[-1]}"
        IFS='/' read -ra APP_LIST <<< "${active_ports_apps_list[$(($portsapps_i+1))]}"
        APP_LIST=(${APP_LIST[*]})
        APP="${APP_LIST[-1]}"
        echo -e "ENABLE $APP IN UNIX FIREWALL:\tsudo ufw allow ${PORT}"
        sudo ufw allow "${PORT}"
    done
    for addother in "${whitelist[@]}"
    do
        sudo ufw allow "${addother}"
    done
    if [[ "$(sudo ufw status)" != *"Status: active"* ]]
    then
        _msg_ "ENABLE UNIX FIREWALL: sudo ufw enable"
        echo y | sudo ufw enable
    else
        _msg_ "UNIX FIREWALL ALREADY ENABLED"
    fi

    sudo ufw status verbose
    _msg_title="$bckp_msg_title"

    if [ ! -e "${cache_path}.configure_ufw_done" ]
    then
        echo -e "$(date)" > "${cache_path}.configure_ufw_done"
    fi
}

if [ -e "${cache_path}.post_config_actions_done" ]
then
    if [ ! -e "${cache_path}.configure_ufw_done" ] || [[ "${arg_list[*]}" == *"ufw"*  ]]
    then
        configure_ufw
    else
        _msg_ "UNIX FIREWALL ALREADY CONFIGURED [for reconfigure: $MYPATH_ ufw]"
        _msg_ "UFW status:"
        sudo ufw status verbose
    fi
else
    _msg_ "configure_ufw skipping - ${cache_path}.post_config_actions_done not exists yet."
fi

if [[ "$ssh_id_rsa_pub" == *"ssh-rsa"* ]]
then
    id_rsa_pubVALID=1
else
    if [ "$ssh_id_rsa_pub" != "$default_id_rsa_pub_value_in_conf" ]
    then
        _msg_ "id_rsa_pub ${RED}INVALID${NC}"
        id_rsa_pubVALID=0
    else
        _msg_ "id_rsa_pub was not set in rpi_config!"
        save_authorized_keys_first_key_to_rpi_config
    fi
fi

id_rsa_pub_is_set=$(cat "$authorized_keys_path" | grep "$ssh_id_rsa_pub")
if [[ "$id_rsa_pub_is_set" == "" ]] && [[ "$id_rsa_pubVALID" -eq 1 ]]
then
    _msg_ "id_rsa_pub from raspi_config setting up: $ssh_id_rsa_pub -> $authorized_keys_path"
    echo -e "$ssh_id_rsa_pub" >> "$authorized_keys_path"
else
    if [ "$id_rsa_pubVALID" -eq 1 ]
    then
        _msg_ "id_rsa_pub was already set (rpi_confing)"
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
