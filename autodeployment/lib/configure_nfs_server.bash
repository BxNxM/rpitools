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

# =============================================================== #
#                          SERVER SETUP                           #
# =============================================================== #
action=false
function create_nfs_file_structure() {

    if [ ! -d "${nfs_shared_folder}" ]
    then
        _msg_ "Create shared folder: ${nfs_shared_folder}"
        sudo bash -c "mkdir -p  ${nfs_shared_folder}"

        _msg_ "Add permissions: chmod -R ${nfs_shared_folder_permissions} ${nfs_shared_folder}"
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

# =============================================================== #
#                        TEST CLIENT SETUP                        #
# =============================================================== #
function create_nfs_client_local_mount_point() {
    local nfs_client_mount_point_path="$1"
    if [ ! -d "$nfs_client_mount_point_path" ]
    then
        _msg_ "Create nfs client local mount point: $nfs_client_mount_point_path"
        sudo mkdir -p "$nfs_client_mount_point_path"
        sudo chown -R ${USER}:${USER} "$nfs_client_mount_point_path"
    else
        _msg_ "nfs client local mount point exists: $nfs_client_mount_point_path"
    fi
}
function mount_nfs_server() {
    local ip="$1"
    local nfs_client_path_to_mount="$2"
    local nfs_client_mount_point_path="$3"
    _msg_ "Manual mount: sudo mount ${ip} ${nfs_client_path_to_mount} ${nfs_client_mount_point_path}"
    sudo mount ${ip}:${nfs_client_path_to_mount} ${nfs_client_mount_point_path}
}
function edit_fstab_for_automount() {
    local ip="$1"
    local nfs_client_path_to_mount="$2"
    local nfs_client_mount_point_path="$3"
    local fstab_setup_cmd="${ip}:${nfs_client_path_to_mount} ${nfs_client_mount_point_path} nfs rw 0 0"
    local fstab_path="/etc/fstab"
    (sudo cat "${fstab_path}" | grep "${fstab_setup_cmd}")
    if [ "$?" -ne 0 ]
    then
        _msg_ "Set $fstab_setup_cmd to $fstab_path"
        sudo bash -c "echo -e ${fstab_setup_cmd} >> ${fstab_path}"

        (sudo cat "${fstab_path}" | grep "${fstab_setup_cmd}")
        if [ "$?" -eq 0 ]
        then
            "Set test mount point for local nfs server was successful"
        fi
    else
        _msg_ "$fstab_setup_cmd already set in $fstab_path"
    fi
    mount_nfs_server "$ip" "$nfs_client_path_to_mount" "$nfs_client_mount_point_path"
}
function create_test_mount_point() {
    local nfs_client_mount_point_path="/media/.local_nfs_client"
    _msg_ "Test client mount point: $nfs_client_mount_point_path"
    create_nfs_client_local_mount_point "$nfs_client_mount_point_path"
    edit_fstab_for_automount "localhost" "$nfs_shared_folder" "$nfs_client_mount_point_path"
}

# =============================================================== #
#                              MAIN                               #
# =============================================================== #
_msg_ "NFS HOWTO: https://www.htpcguides.com/configure-nfs-server-and-nfs-client-raspberry-pi/"
create_nfs_file_structure
if [ ! -f "$CACHE_PATH_is_set" ]
then
    edit_exports_file_and_permissions
else
    _msg_ "NFS was aleady set: $CACHE_PATH_is_set exists"
fi
create_test_mount_point
