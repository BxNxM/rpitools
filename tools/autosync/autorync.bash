#!/bin/bash

ARG_LIST=($@)
DEBUG=false

# script path n name
MYPATH="${BASH_SOURCE[0]}"
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

username="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
sync_configs_path="${MYDIR}/sync_configs/"
autorync_core="${MYDIR}/autorync_core.bash"
autorync_log_path="${MYDIR}/sync.log"

SYNC_CONFIG_LIST=($(find "$sync_configs_path" -type f -iname "*.sync" | grep -v "template"))
echo -e "_____________________________________"
echo -e "AUTOSYNC EXECUTED: $(date)"

# WORKAROUND FOR CRONJOB
if [ "$username" == "" ]
then
    if [ -f "${MYDIR}/.env" ]
    then
        source "${MYDIR}/.env"
    else
        echo -e "ENV ERROR!"
        exit 1
    fi
    username="$USERNAME"
fi

function write_status() {
    local one_execution_log_lines=4
    local get_lines=0
    local log_slice=""
    local status_file_path="${MYDIR}/.status"

    get_lines=$((${#SYNC_CONFIG_LIST[@]}*${one_execution_log_lines}))
    log_slice="$(tail -n "$get_lines" "${REPOROOT}/cache/cron_autosync.log")"
    if [[ "$log_slice" == *"FAILED"* ]]
    then
        echo "fails" > "$status_file_path"
    elif [[ "$log_slice" == *"PROGRESS"* ]]
    then
        echo "warning" > "$status_file_path"
    elif [[ "$log_slice" == *"OK"* ]]
    then
        echo "ok" > "$status_file_path"
    else
        echo "unknown" > "$status_file_path"
    fi

    if [ -f "$status_file_path" ]
    then
        echo -e "UPDATE AUTOSYNC STATUS SUCCESS: $status_file_path"
    else
        echo -e "UPDATE AUTOSYNC STATUS ERROR: $status_file_path"
    fi
}

function run() {
    for config in "${SYNC_CONFIG_LIST[@]}"
    do
        echo -e "SYNC based on: $config"
        log="$(sudo -H -u "$username" bash -c "$autorync_core $config")"
        exitcode="$?"
        if [ "$exitcode" -eq 23 ]
        then
            echo -e "Exitcode with user($username) exitcode: $exitcode maybe permission issues, try as root"
            log="$(sudo bash -c "$autorync_core $config")"
            exitcode="$?"
        fi
        if [ "$exitcode" -ne 0 ] || [ "${ARG_LIST[0]}" == "debug" ]
        then
            echo -e "$log" >> "$autorync_log_path"
            if [ "$exitcode" -eq 0 ]
            then
                echo -e "$config sync OK [$exitcode]"
            elif [ "$exitcode" -eq 245 ]
            then
                echo -e "$config sync already in PROGRESS [$exitcode]"
            else
                echo -e "$config sync FAILED [$exitcode]"
            fi
        else
            echo -e "$config sync OK [$exitcode]"
        fi
    done

    if [ "$DEBUG" == "true" ]
    then
        echo -e "$log -> $autorync_log_path"
    fi

    if [ "${#SYNC_CONFIG_LIST[@]}" -eq 0 ]
    then
        echo -e "AUTOSYNC: modules are not available in $sync_configs_path"
    fi
}

run
write_status

