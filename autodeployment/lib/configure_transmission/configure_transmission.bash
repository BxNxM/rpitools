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
skip_actions=false

source "${MYDIR}/../message.bash"
_msg_title="TRANSMISSION SETUP"

transmission_conf_path="/etc/transmission-daemon/settings.json"
transmission_configuration="$($CONFIGHANDLER -s TRANSMISSION -o activate)"
download_path="$($CONFIGHANDLER -s TRANSMISSION -o download_path)"
incomp_download_path="$($CONFIGHANDLER -s TRANSMISSION -o incomp_download_path)"
username="$($CONFIGHANDLER -s TRANSMISSION -o username)"
passwd="$($CONFIGHANDLER -s TRANSMISSION -o passwd)"
AUTH_REQUIRED=true
RPC_ENABLED=true
HOST_WHITELIST_ENABLED=true
PORT=9091
RPC_WHITELIST='127.0.0.1, 10.0.1.*, 192.168.0.*'

function smart_config_patch() {
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "init" "{DOWNLOAD_DIR}" "$download_path"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{INCOMPLETE_DIR}" "$incomp_download_path"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{USER}" "$username"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{PASSWORD}" "$passwd"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{AUTH_REQUIRED}" "$AUTH_REQUIRED"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{RPC_ENABLED}" "$RPC_ENABLED"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{HOST_WHITELIST_ENABLED}" "$HOST_WHITELIST_ENABLED"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{PORT}" "$PORT"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/settings.json.data" "add" "{RPC_WHITELIST}" "${RPC_WHITELIST}"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$transmission_conf_path" "$MYDIR/config/" "settings.json.finaltemplate" "settings.json.data" "settings.json.final" "settings.json.patch"
    local exitcode="$?"
    if [ "$exitcode" -eq 255 ]
    then
        skip_actions=true
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
    # make usermod
    sudo usermod -a -G debian-transmission "$USER"

    smart_config_patch

    if [ "$skip_actions" != "true" ]
    then
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

