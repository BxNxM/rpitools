#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.samba_configure_is_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

samba_conf_path="/etc/samba/smb.conf"
remote_name="$($confighandler -s SAMBA -o remote_name)"
samba_path="$($confighandler -s SAMBA -o samba_path)"
samba_user="$($confighandler -s SAMBA -o username)"

_msg_title="SAMBA SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
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

function add_configuration() {
    local is_set="$(cat /etc/samba/smb.conf | grep -v grep | grep ${remote_name})"
    if [ "$is_set" == "" ]
    then
        config_text=""
        _msg_ "Configure: $samba_path"
        config_text+="\n[$remote_name]\n"
        config_text+="   Comment = pritools samba set\n"
        config_text+="   Path = ${samba_path}\n"
        config_text+="   Browseable = yes\n"
        config_text+="   Writeable = Yes\n"
        config_text+="   only guest = no\n"
        config_text+="   create mask = 0777\n"
        config_text+="   directory mask = 0777\n"
        config_text+="   Public = yes\n"
        config_text+="   Guest ok = yes\n"
        config_text+="   follow symlinks = yes\n"
        config_text+="   wide links = yes\n"
        _msg_ "Samba configuration:$config_text"
        sudo echo -e "$config_text" >> "$samba_conf_path"
    else
        _msg_ "Samba already set: $samba_path"
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

if [ ! -e "$CACHE_PATH_is_set" ]
then
    set_permissions
    create_shared_folder
    add_configuration
    set_user_and_restart
    echo -e "$(date)" > "$CACHE_PATH_is_set"
else
    _msg_ "Samba is already set: $CACHE_PATH_is_set exists"
fi
