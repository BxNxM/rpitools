#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
activate_backup="$($confighandler -s BACKUP -o activate)"
home_backups_path="$($confighandler -s BACKUP -o backups_path)/backups/users"
system_backups_path="$($confighandler -s BACKUP -o backups_path)/backups/system"
limit="$($confighandler -s BACKUP -o limit)"
sshfs_mount_point_name="$(basename $($confighandler -s SSHFS -o mount_folder_path))"

backuphandler_cron_data_path="${MYDIR}/.backuphandler_cron_data"

echo "activate_backup=$activate_backup" > "$backuphandler_cron_data_path"
echo "home_backups_path=$home_backups_path" >> "$backuphandler_cron_data_path"
echo "system_backups_path=$system_backups_path" >> "$backuphandler_cron_data_path"
echo "limit=$limit" >> "$backuphandler_cron_data_path"
echo "sshfs_mount_point_name=$sshfs_mount_point_name" >> "$backuphandler_cron_data_path"

