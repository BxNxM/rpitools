#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
home_backups_path="$($confighandler -s GENERAL -o home_backups_path)/backups/"
limit=5
if [ ! -d "$home_backups_path" ]
then
    sudo mkdir -p "$home_backups_path"
fi

echo -e "=== BACKUP MAKER ==="
. ${MYDIR}/cache_restore_backup.bash backup

list_users=($(ls -1 /home | grep -v grep | grep -v "backups"))
users=${#list_users[@]}
users_bckp_path="$home_backups_path"

function make_backup_for_every_user() {
    local time=$(date +%s)

    for ((i=0; i<${users}; i++))
    do
        echo -e "[backup_maker.sh] - Create user home backup: ${list_users[$i]} -> ${home_backups_path}"
        cd /home
            user="${list_users[$i]}"
            user_bckp_name="${user}_${time}.tar.gz"
            #targz_cmd=(sudo tar czvf ${users_bckp_path}${user_bckp_name} ${user})
            targz_cmd=(sudo tar czf ${users_bckp_path}${user_bckp_name} ${user})
            "${targz_cmd[@]}"
        cd ~/
done
}

function delete_old_user_backups() {
    for ((i=0; i<${users}; i++))
    do
        get_files_cmd_by_user=($(ls -1tr ${users_bckp_path} | grep "${list_users[$i]}"))
        fies_p_user=${#get_files_cmd_by_user[@]}
        if [ $fies_p_user -gt $limit ]
        then
            echo -e "[backup_maker.sh] - ${list_users[$i]} - Delete backup [limit: $((limit)) actual: ${fies_p_user}] - ${users_bckp_path}${get_files_cmd_by_user[0]} from: ${home_backups_path}"
            sudo rm -r ${users_bckp_path}${get_files_cmd_by_user[0]}
            delete_old_user_backups
        else
            echo -e "[backup_maker.sh] -  ${list_users[$i]} -  Backup status [limit: $((limit)) actual: ${fies_p_user}] from: ${home_backups_path}"
        fi
    done
}

#user backup
make_backup_for_every_user
delete_old_user_backups

#unzip file:
#tar -xzf rebol.tar.gz
