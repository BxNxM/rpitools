#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.nfs_configure_is_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
exports_file="/etc/exports"

source "${MYDIR_}/message.bash"
_msg_title="NFS SETUP"

nfs_shared_folder="$($confighandler -s NFS_SERVER -o nfs_shared_folder)"
nfs_shared_folder_permissions="$($confighandler -s NFS_SERVER -o nfs_shared_folder_permissions)"
nfs_link_downloads_folder="$($confighandler -s NFS_SERVER -o link_downloads)"

action=false
function create_nfs_file_structure() {

    if [ ! -d "${nfs_shared_folder}" ]
    then
        _msg_ "Create shared folder: ${nfs_shared_folder}"
        sudo bash -c "mkdir -p  ${nfs_shared_folder}"

        _msg_ "Add permissions: hmod -R ${nfs_shared_folder_permissions} ${nfs_shared_folder}"
        sudo bash -c "chmod -R ${nfs_shared_folder_permissions} ${nfs_shared_folder}"

        action=true
    else
        _msg_ "Shared folder: ${nfs_shared_folder} already was set"
    fi
}


function edit_exports_file_and_permissions() {
    local export_file_content="${nfs_shared_folder} *(rw,sync)"

    if [ "$action" == "true" ]
    then
        (grep "${nfs_shared_folder}" "${exports_file}")
        if [ "$?" -ne 0 ]
        then
            _msg_ "Add ${export_file_content} to ${exports_file}"
            sudo bash -c "echo -e '${export_file_content}' >> ${exports_file}"

            sudo bash -c "exportfs"

            sudo bash -c "update-rc.d rpcbind enable"
            sudo bash -c "sudo service rpcbind restart"
        else
            _msg_ "${export_file_content} already set in ${exports_file}"
        fi

        echo -e "$(date)" > "$CACHE_PATH_is_set"
    fi
}

function link_downloades_under_shared_folder() {
    local link_to="$1"
    if [ -d "$link_to" ]
    then
        local downloads_folder="$($confighandler -s TRANSMISSION -o download_path)"
        _msg_ "Link: $downloads_folder -> $link_to"
        sudo ln -fs "$downloads_folder" "$link_to"
    else
        _msg_ "Link error: $link_to folder not exists."
    fi
}

_msg_ "NFS HOWTO: https://www.htpcguides.com/configure-nfs-server-and-nfs-client-raspberry-pi/"
if [ ! -f "$CACHE_PATH_is_set" ]
then
    create_nfs_file_structure
    edit_exports_file_and_permissions
else
    _msg_ "NFS was aleady set: $CACHE_PATH_is_set exists"
fi

if [ "$nfs_link_downloads_folder" == "True" ] || [ "$nfs_link_downloads_folder" == "true" ]
then
    link_downloades_under_shared_folder "$nfs_shared_folder"
fi
