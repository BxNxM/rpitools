#!/bin/bash

arg_list=($@)

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
activate_sync="$($confighandler -s AUTOSYNC -o activate)"
schedule='*/1 * * * *'
username="$($confighandler -s GENERAL -o user_name_on_os)"
autosync_full_path="${MYDIR}/autorync.bash"
actual_cron_content="$(crontab -l)"
new_command="${schedule} ${autosync_full_path} >> /home/${username}/rpitools/cache/cron_autosync.log"

echo -e "Actual crontab content:"
echo -e "$actual_cron_content"

source "${MYDIR}/../../prepare/colors.bash"

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
exit 0




