#!/bin/bash

arg_len="$#"
arg_list=("$@")

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

source "${TERMINALCOLORS}"

ssh_passed_state="$($CONFIGHANDLER -s SECURITY -o password_authentication)"
password_auth_for_rpitools_admin="$($CONFIGHANDLER -s SECURITY -o password_auth_for_rpitools_admin)"
ssh_id_rsa_pub="$($CONFIGHANDLER -s SECURITY -o id_rsa_pub)"
user="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
sshd_config_path="/etc/ssh/sshd_config"
authorized_keys_path="$HOME/.ssh/authorized_keys"
default_id_rsa_pub_value_in_conf="write_you_id_rsa_pub_here"
rpi_config_path="$REPOROOT/autodeployment/config/rpitools_config.cfg"
cache_path="$REPOROOT/cache/"
repo_conf_restore_backup="$REPOROOT/tools/cache_restore_backup.bash"

_msg_title="SECURITY [SSH|UFW|GROUPS] SETUP"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${RED}[ $_msg_title ]${NC} - $msg"
}

function change_multi_2line() {
    local from_l1="$1"
    local from_l2="$2"
    local to_l1="$3"
    local to_l2="$4"
    local where="$5"

    if [ ! -z "$from_l1" ] && [ ! -z "$from_l2" ]
    then
        sudo sed -i '/'"${from_l1}"'/ {N; s/'"${from_l1}"'\(.*\n.*\)'"${from_l2}"'/'"${to_l1}"'\1'"${to_l2}"'/;}' "$where"
    else
        _msg_ "2 input parameters needed - NOT PASSED"
    fi
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
        change_parameter "id_rsa_pub.*=.*write_you_id_rsa_pub_here" "id_rsa_pub = ${first_id_rsa_pub}" "$rpi_config_path"

        _msg_ "Validate config after modifications"
        echo -e "$($CONFIGHANDLER -v)"
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
    local whitelist=(137 138 5900)                   # samba ("passive ports[0,1], vnc")
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

function create_linux_groups_for_rpitools() {
    local existsing_groups="/etc/group"
    local rpitools_admin_group="rpitools_admin"
    local rpitools_user_group="rpitools_user"
    local rpitools_user="$user"
    local groups_settings_is_done_cache_indicator="${cache_path}/rpitools_groups_are_done."
    if [ ! -e "$groups_settings_is_done_cache_indicator" ]
    then
        local error_counter=0

        # create groups
        _msg_ "Create groups: $rpitools_admin_group and $rpitools_user_group"
        (grep "$rpitools_admin_group" "$existsing_groups")
        if [ "$?" -ne 0 ]
        then
            _msg_ "Create $rpitools_admin_group"
            sudo bash -c "sudo groupadd $rpitools_admin_group"
            exit_code="$?"
            error_counter=$((error_counter+exit_code))
        else
            _msg_ "$rpitools_admin_group already exists"
        fi
        (grep "$rpitools_user_group" "$existsing_groups")
        if [ "$?" -ne 0 ]
        then
            _msg_ "Create $rpitools_user_group"
            sudo bash -c "sudo groupadd $rpitools_user_group"
            exit_code="$?"
            error_counter=$((error_counter+exit_code))
        else
            _msg_ "$rpitools_user_group already exists"
        fi

        local rpitools_user_existsing_groups=($(cat "$existsing_groups" | grep ":$rpitools_user" | cut -d":" -f1 ))
        if [[ "${rpitools_user_existsing_groups[*]}" != *"$rpitools_admin_group"* ]]
        then
            _msg_ "Add $rpitools_user user to $rpitools_admin_group group"
            _msg_ "\tCMD: sudo usermod -a -G $rpitools_admin_group $rpitools_user"
            sudo bash -c "sudo usermod -a -G $rpitools_admin_group $rpitools_user"
            exit_code="$?"
            error_counter=$((error_counter+exit_code))
        else
            _msg_ "$rpitools_user user is already $rpitools_admin_group group member."
        fi
        if [[ "${rpitools_user_existsing_groups[*]}" != *"$rpitools_user_group"* ]]
        then
            _msg_ "Add $rpitools_user user to $rpitools_user_group group"
            _msg_ "\tCMD: sudo usermod -a -G $rpitools_user_group $rpitools_user"
            sudo bash -c "sudo usermod -a -G $rpitools_user_group $rpitools_user"
            exit_code="$?"
            error_counter=$((error_counter+exit_code))
        else
            _msg_ "$rpitools_user user is already $rpitools_user_group group member."
        fi
        rpitools_user_existsing_groups=($(cat "$existsing_groups" | grep ":$rpitools_user" | cut -d":" -f1 ))
        _msg_ "$rpitools_user [rpitools owner] groups: ${rpitools_user_existsing_groups[*]}"

        _msg_ "Set rpitools repo secondery group to $rpitools_admin_group"
        _msg_ "\tCMD: sudo chgrp -hR $rpitools_admin_group $REPOROOT"
        sudo bash -c "sudo chgrp -hR $rpitools_admin_group $REPOROOT"
        exit_code="$?"
        error_counter=$((error_counter+exit_code))

        if [ "$error_counter" -eq 0 ]
        then
            _msg_ "Groups creation was successful"
            echo -e "$(date)" > "$groups_settings_is_done_cache_indicator"
        else
            _msg_ "Groups creation failed ;( exitcode: $error_counter"
        fi
    else
        _msg_ "rpitools groups are already created [$rpitools_admin_group | $rpitools_user_group]: $groups_settings_is_done_cache_indicator exists."
    fi
}

function create_ssh_key_pair_if_not_exists() {
    if [ ! -d "${HOME}/.ssh" ] || [ ! -f "${HOME}/.ssh/id_rsa" ]
    then
        _msg_ "Generate SSH key for raspberry pi (under ${HOME}/.ssh)"
        mkdir -p "${HOME}/.ssh"
        ssh-keygen -t rsa -N "" -f "${HOME}/.ssh/id_rsa"
    else
        _msg_ "${HOME}/.ssh SSH keys already exists."
    fi
}

#########################################################################################
#                                       MAIN                                            #
#########################################################################################

# CONFIGURE ufw IF .post_config_actions_done EXISTS  - SYSTEM IS REDY TO CONFIURE FIREWALL
if [ -e "${cache_path}.post_config_actions_done" ]
then
    if [ ! -e "${cache_path}.configure_ufw_done" ] || [[ "${arg_list[*]}" == *"ufw"*  ]]
    then
        configure_ufw
    else
        _msg_ "UNIX FIREWALL ALREADY CONFIGURED [for reconfigure: $MYPATH ufw]"
        _msg_ "UFW status:"
        sudo ufw status verbose
    fi
else
    _msg_ "configure_ufw skipping - ${cache_path}.post_config_actions_done not exists yet."
fi

# CHECK ID RSA PUB KEY IN CONFIG FILE
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

# SET ID RSA PUB FROM CONFIG FILE RO AUTHORIZED KEYS SSH FOLDER
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

# SET PasswordAuthentication FOR PASSWORD LIGIN OVER SSH ON | OFF
rpitools_comment_tag="# configured by rpitools"
get_ssh_passwd_state_is_yes=$(cat $sshd_config_path | pcregrep -M "$rpitools_comment_tag.*\n.*PasswordAuthentication yes")
get_ssh_passwd_state_is_no=$(cat $sshd_config_path | pcregrep -M "$rpitools_comment_tag.*\n.*PasswordAuthentication no")
get_ssh_passwd_state_user_set_is_no=$(cat $sshd_config_path | pcregrep -M "Match User $user.*\n.*PasswordAuthentication no")
get_ssh_passwd_state_user_set_is_yes=$(cat $sshd_config_path | pcregrep -M "Match User $user.*\n.*PasswordAuthentication yes")
initial_sshd_config="\n$rpitools_comment_tag\nPasswordAuthentication yes\n\nMatch User $user\nPasswordAuthentication yes"
# Initial sshd configuration
if [ "$(cat "$sshd_config_path" | grep "$rpitools_comment_tag")"  == "" ]
then
    _msg_ "Add rpitools initial sshd config for $sshd_config_path"
    echo -e "$initial_sshd_config" > /tmp/sshdconfrpitools
    sudo bash -c "cat /tmp/sshdconfrpitools >> $sshd_config_path"
else
    _msg_ "Initial rpitools sshd config already added for $sshd_config_path"
fi
# sshd password state handling - global
if [[ "$ssh_passed_state" == "True" ]] || [[ "$ssh_passed_state" == "true" ]]
then
    if [ "$get_ssh_passwd_state_is_yes" == "" ]
    then
        _msg_ "Set PasswordAuthentication yes -> system wide"
        change_multi_2line "$rpitools_comment_tag" "PasswordAuthentication no" "$rpitools_comment_tag" "PasswordAuthentication yes" "$sshd_config_path"
        _msg_ "Restart ssh service: sudo systemctl restart ssh"
        sudo systemctl restart ssh
        _msg_ "SSH status [$?]: $(systemctl is-active ssh)"
    else
        _msg_ "Already set [PasswordAuthentication yes] -> system wide: $get_ssh_passwd_state_is_yes"
    fi
else
    # global password setup
    if [ "$get_ssh_passwd_state_is_no" == "" ]
    then
        _msg_ "Set PasswordAuthentication no -> system wide"
        change_multi_2line "$rpitools_comment_tag" "PasswordAuthentication yes" "$rpitools_comment_tag" "PasswordAuthentication no" "$sshd_config_path"
        _msg_ "Restart ssh service: sudo systemctl restart ssh"
        sudo systemctl restart ssh
        _msg_ "SSH status [$?]: $(systemctl is-active ssh)"
    else
        _msg_ "Already set [PasswordAuthentication no]: $get_ssh_passwd_state_is_no"
    fi
fi

# sshd password state handling - user password setup
if [[ "$password_auth_for_rpitools_admin" == "False" ]] || [[ "$password_auth_for_rpitools_admin" = "false" ]]
then
    if [ "$get_ssh_passwd_state_user_set_is_no" == "" ]
    then
        _msg_ "Set PasswordAuthentication no -> only for $user"
        change_multi_2line "Match User $user" "PasswordAuthentication yes" "Match User $user" "PasswordAuthentication no" "$sshd_config_path"
        _msg_ "Restart ssh service: sudo systemctl restart ssh"
        sudo systemctl restart ssh
        _msg_ "SSH status [$?]: $(systemctl is-active ssh)"
    else
        _msg_ "Already set PasswordAuthentication no -> only for $user"
    fi
else
    if [ "$get_ssh_passwd_state_user_set_is_yes" == "" ]
    then
        _msg_ "Set PasswordAuthentication yes -> only for $user"
        change_multi_2line "Match User $user" "PasswordAuthentication no" "Match User $user" "PasswordAuthentication yes" "$sshd_config_path"
        _msg_ "Restart ssh service: sudo systemctl restart ssh"
        sudo systemctl restart ssh
        _msg_ "SSH status [$?]: $(systemctl is-active ssh)"
    else
        _msg_ "Already set PasswordAuthentication yes -> only for $user"
    fi
fi

# SET RPITOOLS GROUPS
create_linux_groups_for_rpitools
create_ssh_key_pair_if_not_exists
