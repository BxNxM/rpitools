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

function create_official_setup_backup() {
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "archive_factory_backup" "$minidlna_conf_path" "${MYDIR}/config/"
}
create_official_setup_backup

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
    local is_set="$(cat $minidlna_conf_path | grep -v grep | grep ${friendly_name})"
    if [ "$is_set" == "" ]
    then
        if [ ! -e "${minidlna_conf_path}.bak" ]
        then
            sudo cp "$minidlna_conf_path" "${minidlna_conf_path}.bak"
        fi

        # WORKAROUND FOR REPLACING...
        change_line "media_dir=/var/lib/minidlna/" "media_dir=/var/lib/minidlna_separatedirs/" "$minidlna_conf_path"

        config_content=""
        config_content+="media_dir=$media_dir_path\n"
        config_content+="friendly_name=$friendly_name\n"
        config_content+="inotify=yes\n"
        config_content+="wide_links=yes\n"
        config_content+="port=8200\n"
        config_content+="album_art_names=Cover.jpg/cover.jpg/AlbumArtSmall.jpg/albumartsmall.jpg\n"
        config_content+="album_art_names=AlbumArt.jpg/albumart.jpg/Album.jpg/album.jpg\n"
        config_content+="album_art_names=Folder.jpg/folder.jpg/Thumb.jpg/thumb.jpg\n"

        _msg_ "MINIDLNA CUSTOM CONFIG:\n${config_content}"
        echo -e "${config_content}" > "$minidlna_conf_path"

        _msg_ "Restart minidlna service: sudo systemctl restart minidlna"
        sudo systemctl restart minidlna
    else
        _msg_ "minidlna already set: $minidlna_conf_path"
        _msg_ "Official config available: ${minidlna_conf_path}.bak"
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
if [ ! -e "$CACHE_PATH_is_set" ]
then
    set_permissions
    add_configuration
    link_downloads_folder_into_dlna_folder
    echo -e "$(date)" > "$CACHE_PATH_is_set"
else
    _msg_ "minidlna is already set: $CACHE_PATH_is_set exists"
fi



