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
    local cmd=""
    if [ "$REMOTE_SERVER_USER" == "None" ] || [ "$REMOTE_SERVER_USER" == "none" ]
    then
        local_sync
    else
        sync_ssh_key
        remote_sync
    fi
}

#==================== MAIN ======================#
autosync
exit "$EXITCODE"
