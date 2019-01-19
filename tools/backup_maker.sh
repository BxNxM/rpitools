#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
activate_backup="$($confighandler -s BACKUP -o activate)"
home_backups_path="$($confighandler -s BACKUP -o backups_path)/backups/users"
system_backups_path="$($confighandler -s BACKUP -o backups_path)/backups/system"
limit="$($confighandler -s BACKUP -o limit)"

source "${MYDIR}/../prepare/colors.bash"

if [[ "$activate_backup" != "True" ]] && [[ "$activate_backup" != "true" ]]
then
    echo -e "Backup creator for users home folder was not activated [$activate_backup] in rpi_config.cfg"
    echo -e "To activate, use: confeditor -> Y and edit [BACKUP] section"
    exit 1
fi

function create_backup_pathes() {
    if [ ! -d "$home_backups_path" ]
    then
        sudo mkdir -p "$home_backups_path"
    fi
    if [ ! -d "$system_backups_path" ]
    then
        sudo mkdir -p "$system_backups_path"
    fi
}

function make_system_backup() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"

    for ((i=0; i<${#extra_pathes[@]}; i++))
    do
        echo -e "[backup_maker.sh][$(($i+1)) / ${#extra_pathes[@]}] - Create system backup: ${extra_pathes[$i]} -> ${system_backups_path}"
        pushd "$(dirname ${extra_pathes[$i]})"
            comp_name="$(basename ${extra_pathes[$i]})"
            comp_bckp_name="${comp_name}_${time}.tar.gz"
            targz_cmd="sudo tar czf ${system_backups_path}/${comp_bckp_name} ${comp_name}"
            echo -e "CMD: $targz_cmd"
            eval "$targz_cmd"
        popd
done
}

function make_backup_for_every_user() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"

    for ((i=0; i<${#list_users[@]}; i++))
    do
        echo -e "[backup_maker.sh][$(($i+1)) / ${#list_users[@]}]"
        echo -e "\t - Create user home backup: ${list_users[$i]} -> ${home_backups_path}"
        pushd /home
            user="${list_users[$i]}"
            user_bckp_name="${user}_${time}.tar.gz"
            targz_cmd="sudo tar czf ${home_backups_path}/${user_bckp_name} ${user}"
            echo -e "CMD: $targz_cmd"
            eval "$targz_cmd"
        popd
done
}

function delete_obsolete_user_backups() {
    for ((i=0; i<${#list_users[@]}; i++))
    do
        get_files_cmd_by_user=($(ls -1tr ${home_backups_path} | grep "${list_users[$i]}"))
        fies_p_user=${#get_files_cmd_by_user[@]}
        if [ $fies_p_user -gt $limit ]
        then
            echo -e "[backup_maker.sh] - ${list_users[$i]}"
            echo -e "\tDelete backup [limit: $((limit)) actual: ${fies_p_user}]"
            echo -e "\t - ${home_backups_path}${get_files_cmd_by_user[0]} from: ${home_backups_path}"
            sudo rm -r ${home_backups_path}/${get_files_cmd_by_user[0]}
            delete_obsolete_user_backups
        else
            echo -e "[backup_maker.sh] -  ${list_users[$i]}"
            echo -e "\tBackup status [limit: $((limit)) actual: ${fies_p_user}] from: ${home_backups_path}"
        fi
    done
}

function delete_obsolete_system_backups() {
    for ((i=0; i<${#extra_pathes[@]}; i++))
    do
        get_files_cmd_by_systembackup=($(ls -1tr ${system_backups_path} | grep "$(basename ${extra_pathes[$i]})"))
        if [ ${#get_files_cmd_by_systembackup[@]} -gt $limit ]
        then
            echo -e "[backup_maker.sh] - $(basename ${extra_pathes[$i]})"
            echo -e "\tDelete backup [limit: $limit actual: ${#get_files_cmd_by_systembackup[@]}]"
            echo -e "\t - ${get_files_cmd_by_systembackup[0]} from: ${system_backups_path}"
            sudo rm -r "${system_backups_path}/${get_files_cmd_by_systembackup[0]}"
            delete_obsolete_system_backups
        else
            echo -e "[backup_maker.sh] - $(basename ${extra_pathes[$i]})"
            echo -e "\tBackup status [limit: $limit actual: ${#get_files_cmd_by_systembackup[@]}] from: $system_backups_path"
        fi
    done
}

function backup_user_accounts() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"
    local accounts_backup_folder="${system_backups_path}/user_accounts_${time}"

    echo -e "Backup passwords, gooups and so on"

    echo -e "\t[backup_maker.sh] Create folder for user accounts: ${accounts_backup_folder}"
    sudo mkdir -p "${accounts_backup_folder}"

    echo -e "\tbackup: /etc/passwd /etc/shadow /etc/group /etc/gshadow to ${accounts_backup_folder}"
    sudo cp /etc/passwd /etc/shadow /etc/group /etc/gshadow "${accounts_backup_folder}"
}

function delete_obsolete_user_accounts_backup() {
    get_files_cmd_user_accounts=($(ls -1tr ${system_backups_path} | grep "user_accounts_"))

    if [ ${#get_files_cmd_user_accounts[@]} -gt $limit ]
    then
        echo -e "[backup_maker.sh] Delete ${get_files_cmd_user_accounts[0]}"
        echo -e "\tDelete backup [limit: $limit actual: ${#get_files_cmd_user_accounts[@]}]"
        echo -e "\t - ${get_files_cmd_by_systembackup[0]} from: ${system_backups_path}"
        sudo rm -r "${system_backups_path}/${get_files_cmd_user_accounts[0]}"
        delete_obsolete_user_accounts_backup
    else
        echo -e "[backup_maker.sh]"
        echo -e "\tBackup status [limit: $limit actual: ${#get_files_cmd_user_accounts[@]}] from: $system_backups_path"
    fi

}

function restore_user_accounts() {

    echo -e "[backup_maker.sh] restore user accounts"
    # cd $system_backups_path
    # cat passwd.mig >> /etc/passwd
    # cat group.mig >> /etc/group
    # cat shadow.mig >> /etc/shadow
    # /bin/cp gshadow.mig /etc/gshadow

    echo -e "[backup_maker.sh] restore user homes"
    # restore user homes

    echo -e "[backup_maker.sh] reboot"
    #reboot
}

#========================== MAIN ==========================#
echo -e "${YELLOW}========= BACKUP MAKER ==========${NC}"

# create folders for backup
create_backup_pathes

# get actual users list
list_users=($(ls -1 /home | grep -v grep | grep -v "backups"))
extra_pathes=("/var/www/html")

echo -e "${YELLOW}   --- CREATE CACHE BACKUP ---   ${NC}"
# create cache backup
. ${MYDIR}/cache_restore_backup.bash backup

echo -e "${YELLOW}   --- CREATE USER BACKUP ---   ${NC}"
# user backup
make_backup_for_every_user
delete_obsolete_user_backups

echo -e "${YELLOW}   --- CREATE SYSTEM BACKUP ---   ${NC}"
# create other system backups
make_system_backup
delete_obsolete_system_backups

echo -e "${YELLOW}   --- BACKUP USER ACCOUNTS ---   ${NC}"
backup_user_accounts
delete_obsolete_user_accounts_backup

#unzip file:
#tar -xzf rebol.tar.gz
