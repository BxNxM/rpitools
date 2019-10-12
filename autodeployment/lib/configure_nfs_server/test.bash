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

source "${MYDIR}/../message.bash"
_msg_title="NFS SERVER HC CHECK"

nfs_shared_folder="$($CONFIGHANDLER -s NFS_SERVER -o nfs_shared_folder)"
nfs_client_mount_point_path="/media/.local_nfs_client/$(basename $nfs_shared_folder)"

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
            echo -e "Set test mount point for local nfs server was successful"
        fi
    else
        _msg_ "$fstab_setup_cmd already set in $fstab_path"
    fi
    mount_nfs_server "$ip" "$nfs_client_path_to_mount" "$nfs_client_mount_point_path"
}

function create_test_mount_point() {
    _msg_ "Test client mount point: $nfs_client_mount_point_path"
    create_nfs_client_local_mount_point "$nfs_client_mount_point_path"
    edit_fstab_for_automount "localhost" "$nfs_shared_folder" "$nfs_client_mount_point_path"
}

function run_test() {
    local test_file_name="$(cat /proc/sys/kernel/random/uuid).txt"
    local server_testfile_path="$nfs_shared_folder/$test_file_name"
    local client_testfile_path="$nfs_client_mount_point_path/$test_file_name"

    _msg_ "Create file - server side - check"
    echo -e "$(date)" > "$server_testfile_path"
    if [ ! -f "$server_testfile_path" ]
    then
        _msg_ "\t\tCreate $server_testfile_path ${RED}ERROR${NC}"
    else
        if [ ! -f "$client_testfile_path" ]
        then
            _msg_ "Clint ${RED}ERROR${NC}: file not exists: $client_testfile_path"
        else
            _msg_ "NFS SERVER - CLIENT ${GREEN}OK${NC}"
        fi
    fi
    _msg_ "Cleanup test file: $client_testfile_path"
    ls -lht "$client_testfile_path" && rm -f "$client_testfile_path"
}

create_test_mount_point
run_test
