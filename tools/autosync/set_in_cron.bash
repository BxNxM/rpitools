#!/bin/bash

arg_list=($@)

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

source "$TERMINALCOLORS"

activate_sync="$($CONFIGHANDLER -s AUTOSYNC -o activate)"
schedule='*/4 * * * *'
username="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
autosync_full_path="${MYDIR}/autorync.bash"
actual_cron_content="$(crontab -l)"
new_command="${schedule} ${autosync_full_path} >> /home/${username}/rpitools/cache/cron_autosync.log"

echo -e "Actual crontab content:"
echo -e "$actual_cron_content"

if [[ "$activate_sync" != "True" ]] && [[ "$activate_sync" != "true" ]]
then
    echo -e "Backup creator for users home folder was not activated [$activate_sync] in rpi_config.cfg"
    echo -e "To activate, use: confeditor -> Y and edit [AUTOSYNC] section"
    exit 1
fi

function check_servive() {
    local restart_needed="$1"
    local is_active="$(sudo systemctl is-active cron)"
    local is_enabled="$(sudo systemctl is-enabled cron)"

    if [ "$is_enabled" != "enabled" ]
    then
        echo -e "=> enable cron"
        sudo systemctl enable cron
    fi
    if [ "$is_active" != "active" ]
    then
        echo -e "=> activate cron"
        sudo systemctl start cron
    fi

    if [ "$restart_needed" -ne 0 ]
    then
        echo -e "=> reload and restart cron, new entry was added"
        #sudo systemctl reload cron
        sudo systemctl restart cron
    fi
}

function force_clean_locks() {
    # WORKAROUND FOR STUCKED LOCKS
    local locks_path="$MYDIR/.locks"
    local locks=($(ls -1 "$locks_path"))

    for lock in ${locks[@]}
    do
        echo -e "Remove lock: $locks_path/$lock"
        rm "$locks_path/$lock"
    done
}

is_changed=0
if [[ "$actual_cron_content" == *"$new_command"* ]]
then
    echo -e "${YELLOW}$new_command${NC} is already exists in crontab -l"
else
    if [[ "$actual_cron_content" == *"$autosync_full_path"* ]]
    then
        echo -e "Change backuphandler timing parameter ${YELLOW}$schedule${NC}"
        crontab -l > "${MYDIR}/crontab.swp"
            sed -i 's|.*'"${autosync_full_path}"'.*|'"${new_command}"'|g' "${MYDIR}/crontab.swp"
        crontab "${MYDIR}/crontab.swp"
        is_changed=1
    else
        echo -e "Add backuphandler to crontab ${YELLOW}$new_command${NC}"
        crontab -l > "${MYDIR}/crontab.swp"
            echo "${new_command}" >> "${MYDIR}/crontab.swp"
        crontab "${MYDIR}/crontab.swp"
        is_changed=1
    fi
fi

check_servive "$is_changed"
echo -e "Set ${MYDIR}/.env file: USERNAME=$username"
echo "USERNAME=$username" > "${MYDIR}/.env"
force_clean_locks
exit 0



