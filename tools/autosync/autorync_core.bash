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
CONF_TEMPLATE="${MYDIR}/sync_configs/template.sync "

function msg() {
    local msg="$*"
    echo -e "[ autosync ] - $msg"
}

function base_validate_by_template_lines() {
    local template_line_number="$(cat $CONF_TEMPLATE | wc -l)"
    local config_line_number="$(cat ${ARG_LIST[0]} | wc -l)"
    if [ "$template_line_number" -ne "$config_line_number" ]
    then
        msg "Custom sync config is invalid:"
        msg "$CONF_TEMPLATE [$template_line_numbe] vs. ${ARG_LIST[0]} [$config_line_number]"
        exit 1
    fi
}

function sync_lock() {
    local sync_from_path="$1"
    local operation="$2"                # lock | unlock | status
    local locks_folder="${MYDIR}/.locks"
    local actual_lock_path="${locks_folder}/$(basename ${sync_from_path})_$(basename ${ARG_LIST[0]}).lock"
    local active_process=""
    LOCK_STATUS=-1

    if [ ! -d "$locks_folder" ]
    then
        mkdir "$locks_folder"
    fi

    # handle stucked locks
    if [ -f "$actual_lock_path" ]
    then
        active_process="$(ps aux | grep rsync | grep $sync_from_path)"
        if [ "$active_process" == "" ]
        then
            msg "Unlock stucked resource: $actual_lock_path"
            msg "\tLock found: $actual_lock_path but process was not found: $active_process"
            rm -f "$actual_lock_path"
        fi
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
    if [ "${MODE}" == "copy" ]
    then
        msg "Sync locally, MODE: ${MODE}"
        cmd="rsync -avzh ${FROM_PATH} ${TO_PATH}"
        msg "$cmd"
        (rsync -avzh "${FROM_PATH}" "${TO_PATH}")
        EXITCODE="$?"
    elif [ "${MODE}" == "move" ]
    then
        msg "Sync locally, MODE: ${MODE}"
        cmd="rsync -avzh ${FROM_PATH} ${TO_PATH}"
        msg "$cmd"
        (rsync -avzh "${FROM_PATH}" "${TO_PATH}")
        EXITCODE="$?"
        if [ "$EXITCODE" -eq 0 ]
        then
            msg "Remove content from ${FROM_PATH}"
            rm -rf "${FROM_PATH}/"*
        else
            msg "Remove FAILED: ${FROM_PATH}"
            EXITCODE=1
        fi
    elif [ "${MODE}" == "mirror" ]
    then
        msg "Sync locally, MODE: ${MODE}"
        cmd="rsync -avzh --del ${FROM_PATH} ${TO_PATH}"
        msg "$cmd"
        (rsync -avzh --del "${FROM_PATH}" "${TO_PATH}")
        EXITCODE="$?"
    else
        msg "Unknown MODE option: ${MODE}"
        EXITCODE=1
    fi
}

function remote_sync() {
    if [ "${MODE}" == "copy" ]
    then
        msg "Sync with remote, MODE: ${MODE}"
        cmd="rsync -avzh ${FROM_PATH} ${REMOTE_SERVER_USER}@${REMOTE_SERVER_HOST}:${TO_PATH}"
        msg "$cmd"
        (rsync -avzh "${FROM_PATH}" "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}":"${TO_PATH}")
        EXITCODE="$?"
    elif [ "${MODE}" == "move" ]
    then
        msg "Sync with remote, MODE: ${MODE}"
        msg "Sync with remote"
        cmd="rsync -avzh ${FROM_PATH} ${REMOTE_SERVER_USER}@${REMOTE_SERVER_HOST}:${TO_PATH}"
        msg "$cmd"
        (rsync -avzh "${FROM_PATH}" "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}":"${TO_PATH}")
        EXITCODE="$?"
        if [ "$EXITCODE" -eq 0 ]
        then
            msg "Remove content from ${FROM_PATH}"
            rm -rf "${FROM_PATH}/"*
        else
            msg "Remove FAILED: ${FROM_PATH}"
            EXITCODE=1
        fi
    elif [ "${MODE}" == "mirror" ]
    then
        msg "Sync with remote, MODE: ${MODE}"
        cmd="rsync -avzh --del ${FROM_PATH} ${REMOTE_SERVER_USER}@${REMOTE_SERVER_HOST}:${TO_PATH}"
        msg "$cmd"
        (rsync -avzh --del "${FROM_PATH}" "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}":"${TO_PATH}")
        EXITCODE="$?"
    else
        msg "Unknown MODE option: ${MODE}"
        EXITCODE=1
    fi
}

function sync_ssh_key() {
   local authorized_keys=$(sshpass -p "${REMOTE_SERVER_PASSWD}" ssh -o StrictHostKeyChecking=no "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}" 'cat ~/.ssh/authorized_keys')
    local pub_key=$(cat $HOME/.ssh/id_rsa.pub)
    EXITCODE=0

    if [[ "$authorized_keys" == *"$pub_key"*  ]]
    then
        msg "ssh pub key already synced"
    else
        msg "sync ssh pub key"
        sshpass -p "${REMOTE_SERVER_PASSWD}" ssh -o StrictHostKeyChecking=no "${REMOTE_SERVER_USER}"@"${REMOTE_SERVER_HOST}" 'echo '"${pub_key}"' >> /home/'${REMOTE_SERVER_USER}'/.ssh/authorized_keys'
        EXITCODE="$?"
    fi
    if [ "$TMP_PASSWORD_DELETE" == "true" ] || [ "$TMP_PASSWORD_DELETE" == "True" ]
    then
        if [ "$EXITCODE" -eq 0 ]
        then
            msg "Remove password from ${ARG_LIST[0]}"
            sed -i 's/REMOTE_SERVER_PASSWD=.*/REMOTE_SERVER_PASSWD=removed/g' "${ARG_LIST[0]}"
        fi
    else
        msg "Please consider to set TMP_PASSWORD_DELETE=True to improve security!"
    fi
}

function autosync() {
    base_validate_by_template_lines
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
msg "_________________$(date)____________________"
if [ -f "${ARG_LIST[0]}" ]
then
    # source configuration
    source "${ARG_LIST[0]}"
else
    msg "${ARG_LIST[0]} NOT A FILE"
    exit 1
fi
autosync
exit "$EXITCODE"
