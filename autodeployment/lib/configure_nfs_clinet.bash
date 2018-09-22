#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.nfs_configure_is_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
fstab_path="/etc/fstab"

source "${MYDIR_}/message.bash"
_msg_title="NFS CLINET SETUP"

nfs_client_activate="$($confighandler -s NFS_CLIENT -o activate)"
nfs_client_host="$($confighandler -s NFS_CLIENT -o host)"
nfs_client_path_to_mount="$($confighandler -s NFS_CLIENT -o server_mount_path)"
nfs_client_mount_point_path="$($confighandler -s NFS_CLIENT -o local_mount_point)"

function validate_ip() {
    local ip="$1"
    ping -p 22 "$ip" -c 2
    if [ "$?" -eq 0 ]
    then
        _msg_ "$ip is valid"
        ip_is_valid=true
    else
        _msg_ "$ip is invalid"
        ip_is_valid=false
    fi
}

function configure_nfs_clinet() {
    local ip="$1"
    local nfs_client_path_to_mount="$2"
    local nfs_client_mount_point_path="$3"
    sudo mkdir -p "$nfs_client_mount_point_path"
    sudo chown -R ${USER}:${USER} "$nfs_client_mount_point_path"

    edit_fstab_for_automount "$ip"
}

function mount_nfs_server() {
    local ip="$1"
    local nfs_client_path_to_mount="$2"
    local nfs_client_mount_point_path="$3"
    _msg_ "Manual mount"
    sudo mount "${ip}":"${nfs_client_path_to_mount}" "${nfs_client_mount_point_path}"
}

function edit_fstab_for_automount() {
    local ip="$1"
    local nfs_client_path_to_mount="$2"
    local nfs_client_mount_point_path="$3"
    local fstab_setup_cmd="${ip}:${nfs_client_path_to_mount}   ${nfs_client_mount_point_path}   nfs    rw  0  0"
    $(cat ${fstab_path} | grep "${fstab_setup_cmd}")
    if [ "$?" -ne 0 ]
    then
        _msg_ "Set $fstab_setup_cmd to $fstab_path"
        # TODO: edit fstab
        mount_nfs_server "$ip" "$nfs_client_path_to_mount" "$nfs_client_mount_point_path"
    else
        _msg_ "$fstab_setup_cmd already set in $fstab_path"
    fi
}

if [ "$nfs_client_activate" == "True" ] || [ "$nfs_client_activate" == "true" ]
then
    _msg_ "Configure nfs client is required."
    validate_ip "$nfs_client_host"
    if [ "$ip_is_valid" == "true" ]
    then
        configure_nfs_clinet "$nfs_client_host" "$nfs_client_path_to_mount" "$nfs_client_mount_point_path"
    else
        _msg_ "Skipping setup..."
    fi
else
    _msg_ "Configure nfs client is not required."
fi

