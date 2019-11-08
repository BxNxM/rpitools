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
skip_actions=false

# =============================================================== #
#                          SERVER SETUP                           #
# =============================================================== #
function smart_config_patch() {
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/exports.data" "init" "{NFS_SERVER_FOLDER_PATH}" "$nfs_shared_folder"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$exports_file" "$MYDIR/config/" "exports.finaltemplate" "exports.data" "exports.final" "exports.patch"
    local exitcode="$?"
    if [ "$exitcode" -eq 255 ]
    then
        skip_actions=true
    fi
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
        smart_config_patch
        if [ "$skip_actions" == "false" ]
        then
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
#                              MAIN                               #
# =============================================================== #
_msg_ "NFS HOWTO: https://www.htpcguides.com/configure-nfs-server-and-nfs-client-raspberry-pi/"

create_nfs_file_structure
edit_exports_file_and_permissions
start_nfs_server_if_required

_msg_ "\t=== TEST ==="
"${MYDIR}"/test.bash
