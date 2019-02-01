#!/bin/bash

arg_list=($@)

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
activate_backup="$($confighandler -s BACKUP -o activate)"
schedule="$($confighandler -s BACKUP -oschedule)"
backuphandler_full_path="${MYDIR}/backup_handler.bash"
actual_cron_content="$(crontab -l)"
new_command="${schedule} ${backuphandler_full_path} system backup"

echo -e "Actual crontab content:"
echo -e "$actual_cron_content"

source "${MYDIR}/../../prepare/colors.bash"

if [[ "$activate_backup" != "True" ]] && [[ "$activate_backup" != "true" ]]
then
    echo -e "Backup creator for users home folder was not activated [$activate_backup] in rpi_config.cfg"
    echo -e "To activate, use: confeditor -> Y and edit [BACKUP] section"
    exit 1
fi

if [ "$schedule" == "@daily" ] || [ "$schedule" == "@weekly" ] || [ "$schedule" == "@monthly" ]
then
    echo -e "${YELLOW}schedule $schedule is valid${NC}"
else
    echo -e "${YELLOW}|$schedule| invalid schedule time!${NC} Valid: @daily, @weekly, @monthly"
    exit 2
fi

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
    else
        echo -e "Add backuphandler to crontab ${YELLOW}$new_command${NC}"
        crontab -l > "${MYDIR}/crontab.swp"
            echo "${new_command}" >> "${MYDIR}/crontab.swp"
        crontab "${MYDIR}/crontab.swp"
    fi
fi
exit 0




