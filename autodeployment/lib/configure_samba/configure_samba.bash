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

function create_official_setup_backup() {
    local samba_conf_path_bak="${samba_conf_path}.bak"
    if [ ! -e "$samba_conf_path_bak" ]
    then
        _msg_ "Create $samba_conf_path backup -> $samba_conf_path_bak"
        sudo bash -c "cp $samba_conf_path $samba_conf_path_bak"
    fi
}
create_official_setup_backup

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

function add_to_global_section() {
    local parameter="unix extensions = no"
    if [ "$(cat $samba_conf_path | grep ${parameter})" == "" ]
    then
        _msg_ "Add ${parameter} parameter to $samba_conf_path"
        sudo bash -c "sed -i 's/\[global\]/[global]\n  ${parameter}/g' $samba_conf_path"
    else
        _msg_ "${parameter} already exists in $samba_conf_path"
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
if [ ! -e "$CACHE_PATH_is_set" ]
then
    set_permissions
    add_configuration
    add_to_global_section
    set_user_and_restart
    echo -e "$(date)" > "$CACHE_PATH_is_set"
else
    _msg_ "Samba is already set: $CACHE_PATH_is_set exists"
fi

if [ "$samba_link_downloads" == "True" ] || [ "$samba_link_downloads" == "true" ]
then
    link_downloades_under_shared_folder "$samba_path"
fi
