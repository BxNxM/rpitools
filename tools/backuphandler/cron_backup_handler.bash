#!/bin/bash

arg_list=($@)

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

activate_backup="$($CONFIGHANDLER -s BACKUP -o activate)"
schedule="$($CONFIGHANDLER -s BACKUP -o schedule)"
username="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
backuphandler_full_path="${MYDIR}/backup_handler.bash"
actual_cron_content="$(crontab -l)"
new_command="${schedule} ${backuphandler_full_path} system backup >> /home/${username}/rpitools/cache/backuphandler.log"
source "$TERMINALCOLORS"

echo -e "Actual crontab content:"
echo -e "$actual_cron_content"

if [[ "$activate_backup" != "True" ]] && [[ "$activate_backup" != "true" ]]
then
    echo -e "Backup creator for users home folder was not activated [$activate_backup] in rpi_config.cfg"
    echo -e "To activate, use: confeditor -> Y and edit [BACKUP] section"
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

if [ "$schedule" == "@daily" ] || [ "$schedule" == "@weekly" ] || [ "$schedule" == "@monthly" ]
then
    echo -e "${YELLOW}schedule $schedule is valid${NC}"
else
    echo -e "${YELLOW}|$schedule| invalid schedule time!${NC} Valid: @daily, @weekly, @monthly"
    exit 2
fi

is_changed=0
if [[ "$actual_cron_content" == *"$new_command"* ]]
then
    echo -e "${YELLOW}$new_command${NC} is already exists in crontab -l"
else
    if [[ "$actual_cron_content" == *"$backuphandler_full_path"* ]]
    then
        echo -e "Change backuphandler timing parameter ${YELLOW}$schedule${NC}"
        crontab -l > "${MYDIR}/crontab.swp"
            sed -i 's|.*'"${backuphandler_full_path}"'.*|'"${new_command}"'|g' "${MYDIR}/crontab.swp"
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
exit 0




