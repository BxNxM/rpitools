#!/bin/bash

# get arg list
ARG_LIST=($@)
if [ "${#ARG_LIST[@]}" -ne 1 ]
then
    echo -e "ONE ARGUMENT IS REQUIRED: module.sync"
    echo -e "CONTENT:"
    echo -e "#===================== config =====================#"
    echo -e "FROM_PATH=$HOME/foo"
    echo -e "TO_PATH=~/foo_synced"
    echo -e "REMOTE_SERVER_USER=None"
    echo -e "REMOTE_SERVER_PASSWD=None"
    echo -e "REMOTE_SERVER_HOST=None"
    echo -e "#==================================================#"
    exit 1
else
    echo -e "SYNC CONFIG LOAD: ${BASH_SOURCE[0]}"
fi

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source configuration
source "${ARG_LIST[0]}"

function msg() {
    local msg="$*"
    echo -e "[ autosync ] - $msg"
}

function sync_lock() {
    local sync_from_path="$1"
    local operation="$2"                # lock | unlock | status
    local locks_folder="${MYDIR}/.locks"
    local actual_lock_path="${locks_folder}/$(basename ${sync_from_path})_$(basename ${ARG_LIST[0]}).lock"
    LOCK_STATUS=-1

    if [ ! -d "$locks_folder" ]
    then
        mkdir "$locks_folder"
    fi

    if [ "$operation" == "lock" ]
    then
        msg "\tCreate lock under sync in progress: $actual_lock_path"
        echo -e "$(date)" > "$actual_lock_path"
        LOCK_STATUS=1
    elif [ "$operation" == "unlock" ]
    then
        msg "\tRemove lock, sync finished: $actual_lock_path"
        rm -f "$actual_lock_path"
        LOCK_STATUS=0
    elif [ "$operation" == "status" ]
    then
        if [ -f "$actual_lock_path" ]
        then
            msg "\tLOCKED, sync already in progress: $actual_lock_path"
            LOCK_STATUS=1
        else
            LOCK_STATUS=0
            msg "\tUNLOCKED, start sync progress: $actual_lock_path"
        fi
    else
        msg "\tUnknown operation: $operation"
    fi
}

function local_sync() {
    msg "Sync locally"
    cmd="rsync -avzh ${FROM_PATH} ${TO_PATH}"
    msg "$cmd"
    rsync -avzh "${FROM_PATH}" "${TO_PATH}"
    EXITCODE="$?"
}

function remote_sync() {
    msg "Sync with remote"
    cmd="rsync -avzh ${FROM_PATH} ${REMOTE_SERVER_USER}@${REMOTE_SERVER_HOST}:${TO_PATH}"
    msg "$cmd"
    rsync -avzh "${FROM_PATH}" "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}":"${TO_PATH}"
    EXITCODE="$?"
}

function sync_ssh_key() {
   local authorized_keys=$(sshpass -p "${REMOTE_SERVER_PASSWD}" ssh -o StrictHostKeyChecking=no "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}" 'cat ~/.ssh/authorized_keys')
    local pub_key=$(cat $HOME/.ssh/id_rsa.pub)

    if [[ "$authorized_keys" == *"$pub_key"*  ]]
    then
        msg "ssh pub key already synced"
    else
        msg "sync ssh pub key"
        sshpass -p "${REMOTE_SERVER_PASSWD}" ssh -o StrictHostKeyChecking=no "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}" 'echo '"${pub_key}"' >> /home/'${REMOTE_SERVER_USER}'/.ssh/authorized_keys'
        EXITCODE="$?"
    fi
}

function autosync() {
    sync_lock "${FROM_PATH}" "status"
    if [ "$LOCK_STATUS" -eq 0 ]
    then
        sync_lock "${FROM_PATH}" "lock"
        if [ "$REMOTE_SERVER_USER" == "None" ] || [ "$REMOTE_SERVER_USER" == "none" ]
        then
            local_sync
        else
            sync_ssh_key
            remote_sync
        fi
        sync_lock "${FROM_PATH}" "unlock"
    else
        EXITCODE=245
        echo -e "$EXITCODE"
    fi
}

#==================== MAIN ======================#
autosync
exit "$EXITCODE"
