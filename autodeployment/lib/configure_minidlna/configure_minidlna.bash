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

CACHE_PATH_is_set="$REPOROOT/cache/.minidlna_configure_is_done"

source "${MYDIR}/../message.bash"
_msg_title="MINIDLNA SETUP"

minidlna_conf_path="/etc/minidlna.conf"
friendly_name="$($CONFIGHANDLER -s MINIDLNA -o friendly_name)"
media_dir_path="$($CONFIGHANDLER -s MINIDLNA -o dlna_path)"
link_downloads="$($CONFIGHANDLER -s MINIDLNA -o link_downloads)"
transmission_downloads_dir="$($CONFIGHANDLER -s TRANSMISSION -o download_path)"
skip_actions=false

function smart_config_patch() {
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/minidlna.data" "init" "{MINIDLNA_MEDIA_DIR}" "$media_dir_path"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/minidlna.data" "add" "{MINIDLNA_FRIENDLY_NAME}" "$friendly_name"

    "${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$minidlna_conf_path" "$MYDIR/config/" "minidlna.conf.finaltemplate" "minidlna.data" "minidlna.conf.final" "minidlna.conf.patch"
    local exitcode="$?"
    if [ "$exitcode" -eq 255 ]
    then
        skip_actions=true
    fi
}

function create_shared_folder() {
    if [ ! -d "$media_dir_path" ]
    then
        _msg_ "Create minidlna dir: $media_dir_path"
        sudo mkdir -m 1777 "$media_dir_path"
    else
        _msg_ "minidlna dir is already exists: $media_dir_path"
    fi
}

function add_configuration() {

    smart_config_patch
    if [ "$skip_actions" == "false" ]
    then
        _msg_ "Restart minidlna service: sudo systemctl restart minidlna"
        sudo systemctl restart minidlna
    fi
}

function link_downloads_folder_into_dlna_folder() {
    if [ "$link_downloads" == "True" ] || [ "$link_downloads" == "true" ]
    then
        _msg_ "Link downloads: $transmission_downloads_dir -> $media_dir_path"
        ln -s "$transmission_downloads_dir" "$media_dir_path"
    else
        _msg_ "Downloads linking not required."
    fi
}

function set_permissions(){
    _msg_ "Set user permissions: $minidlna_conf_path"
    sudo chmod go+w "$minidlna_conf_path"
}

create_shared_folder
set_permissions
add_configuration
link_downloads_folder_into_dlna_folder



