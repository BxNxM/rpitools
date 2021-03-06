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

CACHE_PATH_is_set="$REPOROOT/cache/.transmission_configure_is_done"

source "${MYDIR}/../message.bash"
_msg_title="TRANSMISSION SETUP"

transmission_conf_path="/etc/transmission-daemon/settings.json"
transmission_configuration="$($CONFIGHANDLER -s TRANSMISSION -o activate)"
download_path="$($CONFIGHANDLER -s TRANSMISSION -o download_path)"
incomp_download_path="$($CONFIGHANDLER -s TRANSMISSION -o incomp_download_path)"
username="$($CONFIGHANDLER -s TRANSMISSION -o username)"
passwd="$($CONFIGHANDLER -s TRANSMISSION -o passwd)"

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

function create_transmission_folders() {
    # create downloads dir
    if [ ! -e "${download_path}" ]
    then
        _msg_ "Create download dir: ${download_path}"
        sudo bash -c "sudo mkdir -p ${download_path}"
        sudo bash -c "sudo chmod 770 ${download_path}"
        sudo bash -c "sudo chgrp debian-transmission ${download_path}"
    else
        _msg_ "Downloads dir exists: ${download_path}"
        sudo bash -c "sudo chmod 770 ${download_path}"
        sudo bash -c "sudo chgrp debian-transmission ${download_path}"
    fi

    # create incomplete downloads dir
    if [ ! -e "${incomp_download_path}" ]
    then
        _msg_ "Create incomplete download dir: ${incomp_download_path}"
        sudo bash -c "sudo mkdir -p ${incomp_download_path}"
        sudo bash -c "sudo chmod 770 ${incomp_download_path}"
        sudo bash -c "sudo chgrp debian-transmission ${incomp_download_path}"
    else
        _msg_ "Incomplete downloads dir exists: ${incomp_download_path}"
        sudo bash -c "sudo chmod 770 ${incomp_download_path}"
        sudo bash -c "sudo chgrp debian-transmission ${incomp_download_path}"
    fi
}

function configure_transmission() {
    if [ ! -e "$CACHE_PATH_is_set" ] && [ -d "${download_path}" ] && [ -d "${incomp_download_path}" ]
    then
        # make usermod
        sudo usermod -a -G debian-transmission "$USER"

        _msg_ "SET DOWNLOADS FOLDER: $download_path IN: $transmission_conf_path"
        #change_parameter "/var/lib/transmission-daemon/downloads" "$download_path" "$transmission_conf_path"
        change_line "download-dir" "    \"download-dir\": \"${download_path}\"," "$transmission_conf_path"

        _msg_ "SET INCOMP DOWNLOADS FOLDER: $incomp_download_path IN: $transmission_conf_path"
        #change_parameter "/var/lib/transmission-daemon/Downloads" "$incomp_download_path" "$transmission_conf_path"
        change_line "incomplete-dir" "    \"incomplete-dir\": \"$incomp_download_path\"," "$transmission_conf_path"
        change_parameter "\"incomplete-dir-enabled\": false" "\"incomplete-dir-enabled\": true" "$transmission_conf_path"

        _msg_ "SET USERNAME TO: $username (FROM transmission)"
        #change_parameter "\"rpc-username\": \"transmission\"" "\"rpc-username\": \"${username}\"" "$transmission_conf_path"
        change_line "rpc-username" "    \"rpc-username\": \"${username}\"," "$transmission_conf_path"

        _msg_ "SET PASSWORD TO: $passwd"
        change_line "rpc-password" "    \"rpc-password\": \""$passwd"\"," "$transmission_conf_path"

        _msg_ "SET WHITELIST:"
        "rpc-whitelist": "127.0.0.1",
        change_line "\"rpc-whitelist\": \"127.0.0.1\"," "    \"rpc-whitelist\": \"127.0.0.1, 10.0.1.*, 192.168.0.*\"," "$transmission_conf_path"

        echo "" > "$CACHE_PATH_is_set"

        _msg_ "Reload transmission: sudo service transmission-daemon reload"
        sudo service transmission-daemon reload
    else
        hostname="$($CONFIGHANDLER -s GENERAL -o custom_hostname)"
        _msg_ "Transmission is already set: $CACHE_PATH_is_set is exists"
        _msg_ "Connect: http://${hostname}"
        _msg_ "Connect: http://$(hostname -I)"
    fi
}

function auto_restart_transmission_setup() {
    _msg_ "RUN: set transmission autorestart edit whitelist"
    output=$("${REPOROOT}/tools/auto_restart_transmission/systemd_setup/set_service.bash")
    _msg_ "$output"
}

# =============================================== MAIN =========================================#
if [ "$transmission_configuration" == "True" ] || [ "$transmission_configuration" == "true" ]
then
    create_transmission_folders
    configure_transmission
    auto_restart_transmission_setup
else
    _msg_ "Transmission not installed - configuration not needed."
fi

