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

activate_backup="$($CONFIGHANDLER -s BACKUP -o activate)"
home_backups_path="$($CONFIGHANDLER -s BACKUP -o backups_path)/backups/users"
system_backups_path="$($CONFIGHANDLER -s BACKUP -o backups_path)/backups/system"
limit="$($CONFIGHANDLER -s BACKUP -o limit)"
sshfs_mount_point_name="$(basename $($CONFIGHANDLER -s SSHFS -o mount_folder_path))"

backuphandler_cron_data_path="${MYDIR}/.backuphandler_cron_data"

echo "activate_backup=$activate_backup" > "$backuphandler_cron_data_path"
echo "home_backups_path=$home_backups_path" >> "$backuphandler_cron_data_path"
echo "system_backups_path=$system_backups_path" >> "$backuphandler_cron_data_path"
echo "limit=$limit" >> "$backuphandler_cron_data_path"
echo "sshfs_mount_point_name=$sshfs_mount_point_name" >> "$backuphandler_cron_data_path"

