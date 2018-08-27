#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.minidlna_configure_is_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

minidlna_conf_path="/etc/minidlna.conf"
friendly_name="$($confighandler -s MINIDLNA -o friendly_name)"
media_dir_path="$($confighandler -s MINIDLNA -o dlna_path)"
link_downloads="$($confighandler -s MINIDLNA -o link_downloads)"
transmission_downloads_dir="$($confighandler -s TRANSMISSION -o download_path)"

_msg_title="MINIDLNA SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
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

if [ ! -e "$CACHE_PATH_is_set" ]
then
    set_permissions
    create_shared_folder
    add_configuration
    link_downloads_folder_into_dlna_folder
    echo -e "$(date)" > "$CACHE_PATH_is_set"
else
    _msg_ "minidlna is already set: $CACHE_PATH_is_set exists"
fi



