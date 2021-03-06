#!/bin/bash

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

source "$TERMINALCOLORS"
cache_indicator_path="$REPOROOT/cache/.custom_user_passwd_set_done"

custom_user="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
custom_password="$($CONFIGHANDLER -s SECURITY -o os_user_passwd)"

_msg_title="SET USER"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_RED}[ $_msg_title ]${NC} - $msg"
}

function create_custom_user() {
    if [ -d /home/${custom_user} ]
    then
        _msg_ "USER ${custom_user} ALREADY EXISTS."
    else
        _msg_ "ADD CUSTOM USER: sudo useradd -c \"rpitools generated user\" -m \"${custom_user}\""
        sudo useradd -c "rpitools generated user" -m "${custom_user}"

        set_user_password
    fi
}

function set_user_password() {

        if [ ! -e "$cache_indicator_path" ]
        then
            _msg_ "SET PASSWORD: echo \"${custom_user}:*******\" | sudo chpasswd"
            echo "${custom_user}:${custom_password}" | sudo chpasswd

            # encripted user password handling
            #echo "fred:fred" | sudo chpasswd --encrypted

            echo -e "$(date)" > "$cache_indicator_path"
        else
            _msg_ "CUSTOM PASSWORD for ${custom_user} WAS ALREADY SET: $cache_indicator_path EXISTS."
        fi
}

function add_to_sudoers() {
    if [ "$(sudo cat /etc/sudoers | grep ${custom_user})" == "" ]
    then
        _msg_ "ADD SUDO RIGHT FOR ${custom_user}: sudo bash -c \"echo '${custom_user}  ALL=(ALL:ALL) ALL' >> /etc/sudoers\""
        sudo bash -c "echo ''"${custom_user}"'  ALL=(ALL:ALL) ALL' >> /etc/sudoers"
    else
        _msg_ "USER ${custom_user} ALREADY IN THE SUDOERS [/etc/sudoers]"
    fi
}

function move_rpitools_repo_under_custom_user() {
    if [ ! -z "$REPOROOT" ] && [ -d "$REPOROOT" ] && [ -d "/home/${custom_user}/" ]
    then
        _msg_ "MOVE RPITOOLS REPO (${REPOROOT}) UNDER /home/${custom_user}/"
        cp -rp "$REPOROOT" "/home/${custom_user}/"
    else
        _msg_ "REPOROOT [${REPOROOT}] OR CUSTOM HOME FOLDER [/home/${custom_user}/] NOT EXISTS."
    fi
}

function del_user_with_home_dir() {
    sudo deluser --remove-home "$1"
}

#create_custom_user
#add_to_sudoers
#move_rpitools_repo_under_custom_user

set_user_password
