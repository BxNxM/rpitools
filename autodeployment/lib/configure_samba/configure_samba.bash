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

source "${TERMINALCOLORS}"
CACHE_PATH_is_set="${REPOROOT}/cache/.samba_configure_is_done"

source "${MYDIR}/../message.bash"
_msg_title="SAMBA SETUP"

samba_conf_path="/etc/samba/smb.conf"
remote_name="$($CONFIGHANDLER -s SAMBA -o remote_name)"
samba_path="$($CONFIGHANDLER -s SAMBA -o samba_path)"
samba_user="$($CONFIGHANDLER -s SAMBA -o username)"
samba_link_downloads="$($CONFIGHANDLER -s SAMBA -o link_downloads)"

function smart_config_patch() {
    # Export template data
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/smb.conf.data" "init" "{SAMBA_FRIENDLY_NAME}" "${remote_name}"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/smb.conf.data" "add" "{SAMBA_SHARED_PATH}" "${samba_path}"
    # Create patch for smb.conf
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$samba_conf_path" "$MYDIR/config/" "smb.conf.finaltemplate" "smb.conf.data" "smb.conf.final" "smb.conf.patch"
}

function create_shared_folder() {
    if [ ! -d "$samba_path" ]
    then
        _msg_ "Create samba dir: $samba_path"
        sudo mkdir -m 1777 "$samba_path"
    else
        _msg_ "Samba dir is alreasy exists: $samba_path"
    fi
}

function set_user_and_restart() {
    _msg_ "Set smbpasswd: sudo smbpasswd -an $samba_user"
    sudo smbpasswd -an "$samba_user"
    _msg_ "Restart samba: sudo /etc/init.d/samba restart"
    sudo /etc/init.d/samba restart
}

function set_permissions(){
    _msg_ "Set user permissions: $samba_conf_path"
    sudo chmod go+w "$samba_conf_path"
}

function link_downloades_under_shared_folder() {
    local link_to="$1"
    if [ -d "$link_to" ]
    then
        local downloads_folder="$($CONFIGHANDLER -s TRANSMISSION -o download_path)"
        _msg_ "Link: $downloads_folder -> $link_to"
        sudo ln -fs "$downloads_folder" "$link_to"
    else
        _msg_ "Link error: $link_to folder not exists."
    fi
}

create_shared_folder
set_permissions
smart_config_patch
set_user_and_restart
echo -e "$(date)" > "$CACHE_PATH_is_set"

if [ "$samba_link_downloads" == "True" ] || [ "$samba_link_downloads" == "true" ]
then
    link_downloades_under_shared_folder "$samba_path"
fi
