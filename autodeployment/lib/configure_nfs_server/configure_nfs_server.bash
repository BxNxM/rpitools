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

CACHE_PATH_is_set="$REPOROOT/cache/.nfs_configure_is_done"
exports_file="/etc/exports"

source "${MYDIR}/../message.bash"
_msg_title="NFS SETUP"

nfs_shared_folder="$($CONFIGHANDLER -s NFS_SERVER -o nfs_shared_folder)"
nfs_shared_folder_permissions="$($CONFIGHANDLER -s NFS_SERVER -o nfs_shared_folder_permissions)"

# =============================================================== #
#                          SERVER SETUP                           #
# =============================================================== #
function smart_config_patch() {
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/exports.data" "init" "{NFS_SERVER_FOLDER_PATH}" "$nfs_shared_folder"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$exports_file" "$MYDIR/config/" "exports.finaltemplate" "exports.data" "exports.final" "exports.patch"
}

action=false
function create_nfs_file_structure() {

    if [ ! -d "${nfs_shared_folder}" ]
    then
        _msg_ "Create shared folder: ${nfs_shared_folder}"
        sudo bash -c "mkdir -p  ${nfs_shared_folder}"

        _msg_ "Add permissions: chmod -R ${nfs_shared_folder_permissions} ${nfs_shared_folder}"
        sudo bash -c "chmod -R ${nfs_shared_folder_permissions} ${nfs_shared_folder}"

    else
        _msg_ "Shared folder: ${nfs_shared_folder} already was set"
    fi
    action=true
    _msg_ "Set permissions: chmod ${nfs_shared_folder_permissions} ${nfs_shared_folder}"
    sudo bash -c "chmod ${nfs_shared_folder_permissions} ${nfs_shared_folder}"
}

function edit_exports_file_and_permissions() {
    if [ "$action" == "true" ]
    then
        (grep "${nfs_shared_folder}" "${exports_file}")
        if [ "$?" -ne 0 ]
        then
            smart_config_patch

            sudo bash -c "exportfs"

            sudo bash -c "update-rc.d rpcbind enable"
            sudo bash -c "sudo service rpcbind restart"
        fi

        echo -e "$(date)" > "$CACHE_PATH_is_set"
    fi
}

function start_nfs_server_if_required() {
    local nfs_server_service_name="nfs-kernel-server"
    if [ "$(systemctl is-active $nfs_server_service_name)" == "inactive" ]
    then
        _msg_ "Start NFS SERVER: $nfs_server_service_nam"
        _msg_ "$(sudo systemctl start $nfs_server_service_name)"
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
    _msg_ "Manual mount: sudo mount ${ip}:${nfs_client_path_to_mount} ${nfs_client_mount_point_path}"
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
    local nfs_client_mount_point_path="/media/.local_nfs_client/$(basename $nfs_shared_folder)"
    _msg_ "Test client mount point: $nfs_client_mount_point_path"
    create_nfs_client_local_mount_point "$nfs_client_mount_point_path"
    edit_fstab_for_automount "localhost" "$nfs_shared_folder" "$nfs_client_mount_point_path"
}

# =============================================================== #
#                              MAIN                               #
# =============================================================== #
_msg_ "NFS HOWTO: https://www.htpcguides.com/configure-nfs-server-and-nfs-client-raspberry-pi/"

create_nfs_file_structure
edit_exports_file_and_permissions

start_nfs_server_if_required
create_test_mount_point
