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

CACHE_PATH_is_set="$REPOROOT/cache/.nfs_client_configure_done"
fstab_path="/etc/fstab"

source "${MYDIR}/../message.bash"
_msg_title="NFS CLINET SETUP"

nfs_client_activate="$($CONFIGHANDLER -s NFS_CLIENT -o activate)"
nfs_client_host="$($CONFIGHANDLER -s NFS_CLIENT -o host)"
nfs_client_path_to_mount="$($CONFIGHANDLER -s NFS_CLIENT -o server_mount_path)"
nfs_client_mount_point_path="$($CONFIGHANDLER -s NFS_CLIENT -o local_mount_point)"

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

function create_nfs_client_local_mount_point() {
    if [ ! -d "$nfs_client_mount_point_path" ]
    then
        _msg_ "Create nfs client local mount point: $nfs_client_mount_point_path"
        sudo mkdir -p "$nfs_client_mount_point_path"
        sudo chown -R ${USER}:${USER} "$nfs_client_mount_point_path"
    else
        _msg_ "nfs client local mount point exists: $nfs_client_mount_point_path"
    fi
}

function configure_nfs_clinet() {
    local ip="$1"
    local nfs_client_path_to_mount="$2"
    local nfs_client_mount_point_path="$3"
    create_nfs_client_local_mount_point
    edit_fstab_for_automount "$ip" "$nfs_client_path_to_mount" "$nfs_client_mount_point_path"
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
    (sudo cat "${fstab_path}" | grep "${fstab_setup_cmd}")
    if [ "$?" -ne 0 ]
    then
        _msg_ "Set $fstab_setup_cmd to $fstab_path"
        sudo bash -c "echo -e ${fstab_setup_cmd} >> ${fstab_path}"

        (sudo cat "${fstab_path}" | grep "${fstab_setup_cmd}")
        if [ "$?" -eq 0 ]
        then
            echo -e "$(date)" > "$CACHE_PATH_is_set"
        fi
    else
        _msg_ "$fstab_setup_cmd already set in $fstab_path"
    fi
    mount_nfs_server "$ip" "$nfs_client_path_to_mount" "$nfs_client_mount_point_path"
}

if [ -e "$CACHE_PATH_is_set" ]
then
    _msg_ "NFS client configured: $CACHE_PATH_is_set exists."
    exit 0
fi

if [ "$nfs_client_activate" == "True" ] || [ "$nfs_client_activate" == "true" ]
then
    _msg_ "Configure nfs client is required."
    create_nfs_client_local_mount_point
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

