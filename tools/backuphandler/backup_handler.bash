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

activate_backup="$($CONFIGHANDLER -s BACKUP -o activate)"
home_backups_path="$($CONFIGHANDLER -s BACKUP -o backups_path)/backups/users"
system_backups_path="$($CONFIGHANDLER -s BACKUP -o backups_path)/backups/system"
limit="$($CONFIGHANDLER -s BACKUP -o limit)"
instantiation_UUID="$(cat ${REPOROOT}/cache/.instantiation_UUID)"
sshfs_mount_point_name="$(basename $($CONFIGHANDLER -s SSHFS -o mount_folder_path))"
touched_configs_path="${REPOROOT}/config/"
ERRORS=0

source "${REPOROOT}/prepare/colors.bash"

function _msg_ () {
    local msg="$*"
    echo -e "[$(date)]${BLUE}[backuphandler]${NC} $msg"
}

# crontab - rpitools config get activate fix
if [ "$activate_backup" == "" ]
then
    if [ -f "${MYDIR}/.backuphandler_cron_data" ]
    then
        _msg_ "Fix backup config data for cron job, read from: ${MYDIR}/.backuphandler_cron_data"
        source "${MYDIR}/.backuphandler_cron_data"
    else
        _msg_ "${MYDIR}/.backuphandler_cron_data file for cron job NOT EXISTS! EXIT"
        write_status_file 1
        exit 1
    fi
fi

# check backup activate status
if [[ "$activate_backup" != "True" ]] && [[ "$activate_backup" != "true" ]]
then
    _msg_ "Backup creator for users home folder was not activated [$activate_backup] in rpi_config.cfg"
    _msg_ "To activate, use: confeditor edit and edit [BACKUP] section"
    write_status_file 1
    exit 1
else
    _msg_ "Backup creator for users home folder was activated [$activate_backup] in rpi_config.cfg"
fi

__PROCESS_I=0
function progress_indicator() {
    local spin=("-" "\\" "|" "/")
    echo -ne "\b${spin[$__PROCESS_I]}"
    __PROCESS_I=$((__PROCESS_I+1))
    echo -ne "\b"

    if [ "$__PROCESS_I" -gt "${#spin[@]}" ]
    then
        __PROCESS_I=0
    fi
}

function create_backup_pathes() {
    if [ ! -d "$home_backups_path" ]
    then
        sudo mkdir -p "$home_backups_path"
        ERRORS=$(($ERRORS+$?))
    fi
    if [ ! -d "$system_backups_path" ]
    then
        sudo mkdir -p "$system_backups_path"
        ERRORS=$(($ERRORS+$?))
    fi
}

function write_status_file() {
    local errors="$1"
    if [ "$errors" == "" ]
    then
        ERRORS="$ERRORS"
    else
        ERRORS="$errors"
    fi

    MYPATH="${BASH_SOURCE[0]}"
    MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local status_path="${MYDIR}/.status"
    if [ "$ERRORS" -eq 0 ]
    then
        echo "ok" > "$status_path"
    elif [ "$ERRORS" -gt 0 ] && [ "$errors" != "" ]
    then
        echo "fails" > "$status_path"
    else
        echo "warning" > "$status_path"
    fi
}

# ======================================================================================================================= #
# =========================================================== BACKUP ==================================================== #
# ======================================================================================================================= #
# BACKUP: extra folder, example html
function make_system_backup() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"

    for ((i=0; i<${#extra_pathes[@]}; i++))
    do
        if [ -e "${extra_pathes[$i]}" ]
        then
            _msg_ "[$(($i+1)) / ${#extra_pathes[@]}] - Create system backup: ${extra_pathes[$i]} -> ${system_backups_path}"
            pushd "$(dirname ${extra_pathes[$i]})"
                comp_name="$(basename ${extra_pathes[$i]})"
                comp_bckp_name="${comp_name}_${time}.tar.gz"
                targz_cmd="sudo tar czf ${system_backups_path}/${comp_bckp_name} ${comp_name}"
                _msg_ "CMD: $targz_cmd"
                eval "$targz_cmd"
                ERRORS=$(($ERRORS+$?))
            popd
        else
            _msg_ "path not exists: ${extra_pathes[$i]} can't backup"
            ERRORS=$(($ERRORS+1))
        fi
    done
    backup_touched_system_configs
}

# BACKUP: every users home folder
function make_backup_for_every_user() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"

    for ((i=0; i<${#list_users[@]}; i++))
    do
        _msg_ "[$(($i+1)) / ${#list_users[@]}]"
        _msg_ "\t - Create user home backup: ${list_users[$i]} -> ${home_backups_path}"
        pushd /home
            user="${list_users[$i]}"
            local exclude_restored_folders=($(ls -1 "${user}" | grep "restored_"))
            local exclude_restored_folders2=($(ls -1 "${user}" | grep "$sshfs_mount_point_name"))
            local exclude_parameters=""
            _msg_ "exclude folders in ${user}: ${exclude_restored_folders[*]}"
            for exclude in "${exclude_restored_folders[@]}"
            do
                exclude_parameters+="--exclude ./${user}/${exclude} "
            done
            for exclude in "${exclude_restored_folders2[@]}"
            do
                exclude_parameters+="--exclude ./${user}/${exclude} "
            done
            user_bckp_name="${user}_${time}.tar.gz"
            targz_cmd="sudo tar czf ${home_backups_path}/${user_bckp_name} ${exclude_parameters} ${user}"
            _msg_ "CMD: $targz_cmd"
            output=$(eval "$targz_cmd 2>&1")
            exitc_="$?"
            if [ "$exitc_" -ne 0 ] && [[ "$output" == *"file changed as we read it"* ]]
            then
                exitc_=0
            fi
            ERRORS=$(($ERRORS+$exitc_))
            _msg_ "$output"
        popd
    done
}

# CLEANUP: clean up user home backups
function delete_obsolete_user_backups() {
    for ((i=0; i<${#list_users[@]}; i++))
    do
        get_files_cmd_by_user=($(ls -1tr ${home_backups_path} | grep "${list_users[$i]}"))
        fies_p_user=${#get_files_cmd_by_user[@]}
        if [ $fies_p_user -gt $limit ]
        then
            _msg_ "- ${list_users[$i]}"
            _msg_ "\tDelete backup [limit: $((limit)) actual: ${fies_p_user}]"
            _msg_ "\t - ${home_backups_path}${get_files_cmd_by_user[0]} from: ${home_backups_path}"
            sudo rm -r ${home_backups_path}/${get_files_cmd_by_user[0]}
            ERRORS=$(($ERRORS+$?))
            delete_obsolete_user_backups
        else
            _msg_ "-  ${list_users[$i]}"
            _msg_ "\tBackup status [limit: $((limit)) actual: ${fies_p_user}] from: ${home_backups_path}"
        fi
    done
}

# CLEANUP: clean up extra folder system backups
function delete_obsolete_system_backups() {
    for ((i=0; i<${#extra_pathes[@]}; i++))
    do
        get_files_cmd_by_systembackup=($(ls -1tr ${system_backups_path} | grep "$(basename ${extra_pathes[$i]})"))
        if [ ${#get_files_cmd_by_systembackup[@]} -gt $limit ]
        then
            _msg_ "- $(basename ${extra_pathes[$i]})"
            _msg_ "\tDelete backup [limit: $limit actual: ${#get_files_cmd_by_systembackup[@]}]"
            _msg_ "\t- ${get_files_cmd_by_systembackup[0]} from: ${system_backups_path}"
            sudo rm -r "${system_backups_path}/${get_files_cmd_by_systembackup[0]}"
            ERRORS=$(($ERRORS+$?))
            delete_obsolete_system_backups
        else
            _msg_ " - $(basename ${extra_pathes[$i]})"
            _msg_ "\tBackup status [limit: $limit actual: ${#get_files_cmd_by_systembackup[@]}] from: $system_backups_path"
        fi
    done
}

# BACKUP: backup user passwords, linux groups, and so on
function backup_user_accounts() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"
    local accounts_backup_folder="${system_backups_path}/user_accounts_${time}"
    local accounts_backup_UUID="${accounts_backup_folder}/UUID"

    _msg_ "Backup passwords, goups and so on"

    _msg_ "\tCreate folder for user accounts: ${accounts_backup_folder}"
    sudo mkdir -p "${accounts_backup_folder}"
    ERRORS=$(($ERRORS+$?))

    _msg_ "\tbackup: /etc/passwd /etc/shadow /etc/group /etc/gshadow to ${accounts_backup_folder}"
    sudo cp /etc/passwd /etc/shadow /etc/group /etc/gshadow "${accounts_backup_folder}"
    ERRORS=$(($ERRORS+$?))
    _msg_ "\tbackup /etc/sudoers -> ${accounts_backup_folder}/sudoers"
    sudo bash -c "cat /etc/sudoers > ${accounts_backup_folder}/sudoers"
    sudo bash -c "echo $instantiation_UUID > $accounts_backup_UUID"
}

# CLEANUP: clean up user accounts folders
function delete_obsolete_user_accounts_backup() {
    get_files_cmd_user_accounts=($(ls -1tr ${system_backups_path} | grep "user_accounts_"))

    if [ ${#get_files_cmd_user_accounts[@]} -gt $limit ]
    then
        _msg_ "Delete ${get_files_cmd_user_accounts[0]}"
        _msg_ "\tDelete backup [limit: $limit actual: ${#get_files_cmd_user_accounts[@]}]"
        _msg_ "\t - ${get_files_cmd_by_systembackup[0]} from: ${system_backups_path}"
        sudo rm -r "${system_backups_path}/${get_files_cmd_user_accounts[0]}"
        ERRORS=$(($ERRORS+$?))
        delete_obsolete_user_accounts_backup
    else
        _msg_ ""
        _msg_ "\tBackup status [limit: $limit actual: ${#get_files_cmd_user_accounts[@]}] from: $system_backups_path"
    fi
}

# BACKUP: backup all touched config files
function backup_touched_system_configs() {
    local time="$(date +%Y-%m-%d_%H-%M-%S)"
    local touched_configs_backup_folder="${system_backups_path}/touched_configs_${time}"
    local touched_conigs_list=($(ls -1 $touched_configs_path))

    # backup
    _msg_ "Backup touched system config files, !!! not restoring automaticly !!!"
    sudo mkdir -p "${touched_configs_backup_folder}"
    ERRORS=$(($ERRORS+$?))

    for conf in "${touched_conigs_list[@]}"
    do
        local config_path="${touched_configs_path}/${conf}"
        if [ -f "$config_path" ]
        then
            _msg_ "Backup touched system config: $config_path -> $touched_configs_backup_folder"
            sudo bash -c "cp --preserve=links $config_path $touched_configs_backup_folder"
            ERRORS=$(($ERRORS+$?))
        fi
    done
    delete_obsolete_touched_config_backup
}

# CLEANUP: clean up touched config files folder
function delete_obsolete_touched_config_backup() {
    get_files_cmd_user_accounts=($(ls -1tr ${system_backups_path} | grep "touched_configs_"))

    if [ ${#get_files_cmd_user_accounts[@]} -gt $limit ]
    then
        _msg_ "Delete ${get_files_cmd_user_accounts[0]}"
        _msg_ "\tDelete backup [limit: $limit actual: ${#get_files_cmd_user_accounts[@]}]"
        _msg_ "\t - ${get_files_cmd_by_systembackup[0]} from: ${system_backups_path}"
        sudo rm -r "${system_backups_path}/${get_files_cmd_user_accounts[0]}"
        ERRORS=$(($ERRORS+$?))
        delete_obsolete_touched_config_backup
    else
        _msg_ ""
        _msg_ "\tBackup status [limit: $limit actual: ${#get_files_cmd_user_accounts[@]}] from: $system_backups_path"
    fi

}
# ======================================================================================================================= #
# ========================================================== RESTORE ==================================================== #
# ======================================================================================================================= #
# RESTORE: user accounts
function restore_user_accounts() {
    local backup_path="$1"
    local force="$2"               # 1- true, 0 - false
    if [ -z "$force" ] || [ "$force" == "" ]
    then
        force=0
    fi
    local accounts_orig_path_list=("/etc/passwd" "/etc/group" "/etc/shadow" "/etc/gshadow")
    account_restore_action=0

    if [ -d "$backup_path" ]
    then
        sudo bash -c "chmod -R o+r ${backup_path}"

        # check instantiation UUID - migration or not...
        local backup_UUID="$(cat ${backup_path}/UUID)"
        if [ "$backup_UUID" != "$instantiation_UUID" ] || [ "$force" -eq 1 ]
        then
            _msg_ "UUID validate OK: $backup_UUID, user migartion"
            # get backup file list
            local user_accounts_backup_files=($(ls -1tr ${backup_path}))

            _msg_ "restore user accounts:\n${user_accounts_backup_files[*]}"
            for file in "${user_accounts_backup_files[@]}"
            do
                # get backup file full path
                local backup_file="${backup_path}/$file"
                for acconts_orig_path in "${accounts_orig_path_list[@]}"
                do
                    if [ "$file" == "$(basename ${acconts_orig_path})" ]
                    then
                        _msg_ "Attempt to Restore backup: $backup_file -> ${acconts_orig_path}"
                        while read -r line
                        do
                            local key="$(echo "$line" | cut -d':' -f'1')"
                            local orig_is_contains_key="$(sudo bash -c "cat ${acconts_orig_path} | grep ${key}")"
                            if [ "$orig_is_contains_key" == "" ]
                            then
                                _msg_ "[i] RESTORE REQUIRED:"
                                _msg_ "\tKey have to be restore: $key"
                                _msg_ "\tLine for key: $line"
                                _msg_ "\tfrom: $backup_file"
                                _msg_ "\tto: $acconts_orig_path"
                                echo "$line" > /tmp/catitto
                                sudo bash -c "sudo cat /tmp/catitto >> $acconts_orig_path"
                                ERRORS=$(($ERRORS+$?))
                                sudo bash -c "rm -f /tmp/catitto"
                                account_restore_action=$(($account_restore_action+1))
                            else
                                progress_indicator
                            fi
                        done < "$backup_file"
                    fi
                done
            done

            # restore sudoers file if different
            if [ "$(sudo bash -c "sudo diff -q /etc/sudoers ${backup_path}/sudoers")" != "" ]
            then
                _msg_ "Attempt to Restore backup: ${backup_path}/sudoers -> /etc/sudoers"
                sudo bash -c "cat ${backup_path}/sudoers > /etc/sudoers"
                ERRORS=$(($ERRORS+$?))
                account_restore_action=$(($account_restore_action+1))
            else
                _msg_ "Restore backup is not necesarry /etc/sudoers not changed"
            fi

            # manual merge for user accounts
            useraccounts_manual_merge "${backup_path}"
            sudo bash -c "chmod -R o-r ${backup_path}"
            ERRORS=$(($ERRORS+$?))

            if [ "$account_restore_action" -ne 0 ]
            then
                _msg_ "Restore was successful, restored elements: $account_restore_action"
            else
                _msg_ "Restore was not necessarry, your system is up and running"
            fi
        else
            _msg_ "UUID $backup_UUID == $instantiation_UUID"
            _msg_ "FROM PATH: $backup_path\n$(ls -lath $backup_path)"
            _msg_ "[WARNING] User migration in the same system is risky (UUID: $instantiation_UUID)"
            read -p "Are you sure, you want to restore user accounts?[yes|no] " answer
            if [ "$answer" == "yes" ]
            then
                restore_user_accounts "$backup_path" "1"
            fi
        fi
    fi
}

function useraccounts_manual_merge() {
    local last_sysbackup_path="$1"
    local backup_accout_files_list=($(ls -1 "$last_sysbackup_path"))
    read_timeout_sec=60
    echo -ne "Do you want to merge user accounts manually, for the more efficiat result? [Y|N]"
    read -t $read_timeout_sec answer
    case "$answer" in
        [yY])
            _msg_ "Merge manually, mergetool vimdiff"
            sleep 2
            for accfile in "${backup_accout_files_list[@]}"
            do
                if [ "$accfile" != "UUID" ]
                then
                    local backup_file_path="${last_sysbackup_path}/${accfile}"
                    local system_acc_file="/etc/${accfile}"
                    _msg_ "Diff files: $backup_file_path <-> $system_acc_file"
                    sleep 2
                    sudo vimdiff "$backup_file_path" "$system_acc_file"
                    account_restore_action=$(($account_restore_action+1))
                fi
            done
            ;;
        [nN])
            _msg_ "Then, goodbye"
            ;;
        *)
            _msg_ "Timeout exceeded [$read_timeout_sec]"
            ;;
    esac
}

# RESTORE: home folders for every user
function restore_user_home_folders() {
    local specific_user="$1"
    local user_backups=($(ls -1tr ${home_backups_path}))
    local existing_user_raw_accounts_list=()

    # get existing user accounts name (usernames)
    _msg_ "Get existsing user accounts raw data - before restoring home folders"
    while read -r line
    do
        progress_indicator
        existing_user_raw_accounts_list+=("$(echo "$line" | cut -d':' -f'1')")
    done < /etc/passwd

    # get usernames list
    username_list=()
    for user_backup in "${user_backups[@]}"
    do
        username="$(echo ${user_backup} | cut -d'_' -f'1')"
        if [[ "${username_list[*]}" != *"$username"* ]]
        then
            if [[ "${existing_user_raw_accounts_list[*]}" == *"$username"* ]]
            then
                _msg_ "=> Add user to restore: $username"
                username_list+=("$username")
            else
                _msg_ "=> Skip user to restore: $username"
                _msg_ "   => account not found, only home folder..."
            fi
        fi
    done

    _msg_ "Existsing user backups: ${username_list[*]}"
    local latest_user_backups_list=()
    for username in "${username_list[@]}"
    do
        local user_backups=($(ls -1t ${home_backups_path} | grep "$username"))
        local latest_user_backups_list+=("${user_backups[0]}")
    done

    _msg_ "${latest_user_backups_list[*]}"

    # restore only the selected user backup - hack username_list lsit
    if [ "$specific_user" != "" ]
    then
        for username in "${username_list[@]}"
        do
            if [ "$username" == "$specific_user" ]
            then
                username_list=("$specific_user")
                for latest_user_backup in "${latest_user_backups_list[@]}"
                do
                    if [[ "$latest_user_backup" == *"${specific_user}_"* ]]
                    then
                        latest_user_backups_list=("$latest_user_backup")
                        break
                    fi
                done
            fi
        done
    fi

    # iterate over username_list and restore backups
    _msg_ "restore user homes"
    for ((k=0; k<${#username_list[@]}; k++))
    do
        backup_path="${home_backups_path}/${latest_user_backups_list[$k]}"
        user_home_path="/home/${username_list[$k]}"
        _msg_ "$backup_path -> $user_home_path"
        if [ -d "$user_home_path" ]
        then
            _msg_ "User home is exists: ${username_list[$k]}"
            _msg_ "Create subfoder: ${user_home_path}/restored_$(basename $backup_path)"
            sudo bash -c "mkdir -p ${user_home_path}/restored_$(basename $backup_path)"
            ERRORS=$(($ERRORS+$?))
            _msg_ "tar -xzf $backup_path -C ${user_home_path}/restored_$(basename $backup_path)"
            sudo bash -c "tar -xzf $backup_path -C ${user_home_path}/restored_$(basename $backup_path)"
            ERRORS=$(($ERRORS+$?))
            sudo bash -c "chown -R ${username_list[$k]} ${user_home_path}/restored_$(basename $backup_path)"
            ERRORS=$(($ERRORS+$?))
        else
            _msg_ "Create home folder for ${username_list[$k]}"
            _msg_ "tar -xzf $backup_path -C /home"
            sudo bash -c "tar -xzf $backup_path -C /home"
            ERRORS=$(($ERRORS+$?))
            sudo bash -c "chown -R ${username_list[$k]} ${user_home_path}"
            ERRORS=$(($ERRORS+$?))
        fi
    done
}

# RESTORE: extra system fodlers
function restore_extra_system_folders() {
    local folders_to_restore=($@)
    _msg_ "restore extra folders"

    for ((p=0; p<"${#folders_to_restore[@]}"; p++))
    do
        backup_from="${folders_to_restore[$p]}"
        backup_to="${extra_pathes[$p]}"
        _msg_ "Retore: tar -xzf $backup_from -C $backup_to"
        sudo bash -c "tar -xzf $backup_from -C $backup_to"
        ERRORS=$(($ERRORS+$?))
        _msg_ "cp -r $backup_to/$(basename $backup_to)/* $backup_to"
        sudo bash -c "cp -r $backup_to/$(basename $backup_to)/* $backup_to"
        ERRORS=$(($ERRORS+$?))
        _msg_ "rm -rf $backup_to/$(basename $backup_to)"
        sudo bash -c "rm -rf $backup_to/$(basename $backup_to)"
        ERRORS=$(($ERRORS+$?))
    done
}

function system_restore() {
    local system_user_accounts_backups=($(ls -1tr ${system_backups_path} | grep "user_accounts_"))
    local latest_user_accounts_backup_path="${system_backups_path}/${system_user_accounts_backups[$((${#system_user_accounts_backups[@]}-1))]}"

    local last_extra_system_backups_list=()
    for extra in "${extra_pathes[@]}"
    do
        local system_extra_pathes_backup=($(ls -1tr ${system_backups_path} | grep "$(basename ${extra})"))
        _msg_ "$system_extra_pathes_backup"
        local last_extra_system_backup="${system_backups_path}/${system_extra_pathes_backup[$((${#system_extra_pathes_backup[@]}-1))]}"
        last_extra_system_backups_list+=("${last_extra_system_backup}")
    done

    _msg_ "=> USER ACCOUNTS LAST BACKUP: ${latest_user_accounts_backup_path}"
    _msg_ "=> EXTRA SYSTEM BACKUP(S): ${last_extra_system_backups_list[*]}"

    _msg_ "${YELLOW}   --- RESTORE USER ACCOUNTS ---   ${NC}"
    restore_user_accounts "${latest_user_accounts_backup_path}"
    if [ -z "$SKIPHOMEDIRS" ] || [ "$SKIPHOMEDIRS" -eq 0 ]
    then
        _msg_ "${YELLOW}   --- RESTORE USER HOME FOLDERS ---   ${NC}"
        restore_user_home_folders
        _msg_ "${YELLOW}   --- RESTORE EXTRA SYSTEM FOLDERS ---   ${NC}"
        restore_extra_system_folders "${last_extra_system_backups_list[@]}"
    fi

    _msg_ "Force refresh user environment - if it conatins dynamic env indicators..."
    source "${MYDIR}/.rpienv" "-f -p"
    # fix user groups automaticly
    _msg_ "${YELLOW}Restore user groups from code, with${NC} usermanager --fixusergroups"
    . "${USERMANAGER}" "--fixusergroups"

    if [ "$account_restore_action" -ne 0 ]
    then
        _msg_ "system needs a reboot now..."
        sleep 1
        sudo reboot
    fi
}

function users_backup() {
    _msg_ "${YELLOW}   --- CREATE CACHE BACKUP ---   ${NC}"
    # create cache backup
    . "${MYDIR}/../cache_restore_backup.bash" "backup"

    _msg_ "${YELLOW}   --- CREATE USER BACKUP ---   ${NC}"
    # user backup
    make_backup_for_every_user
    delete_obsolete_user_backups
}

function full_system_backup() {
    if [ "$SKIPHOMEDIRS" == 0 ]
    then
        users_backup
    else
        _msg_ "Skip user home folders backup --skiphomedirs parameter detected"
    fi

    _msg_ "${YELLOW}   --- CREATE SYSTEM BACKUP ---   ${NC}"
    # create other system backups
    make_system_backup
    delete_obsolete_system_backups

    _msg_ "${YELLOW}   --- BACKUP USER ACCOUNTS ---   ${NC}"
    backup_user_accounts
    delete_obsolete_user_accounts_backup
}

function show_backup_struct() {
    local backup_root_path="$(dirname $system_backups_path)"
    _msg_ "backups root path: $backup_root_path"
    _msg_ "actual content:"
    tree -L 2 "$backup_root_path"
    _msg_ "All backups size: $(du -sh $backup_root_path)"
}

# ======================================================================================================================= #
# ================================================== BACKUPHANDLER CORE ================================================= #
# ======================================================================================================================= #
function init_backup_handler() {
    # create folders for backup
    create_backup_pathes

    # get actual users list
    list_users=($(ls -1 /home | grep -v grep | grep -v "backups"))
    extra_pathes=("/var/www/html" "/var/lib/transmission-daemon/.config/transmission-daemon/torrents/" "/var/spool/cron/")

    sudo bash -c "chmod -R o+r $(dirname $system_backups_path)"
    ERRORS=$(($ERRORS+$?))
}

function main() {
    _msg_ "${YELLOW}===================== BACKUP HANDLER ======================${NC}"
    init_backup_handler

    # handle extra parameters, swithches
    if [[ "${arg_list[*]}" == *"--skiphomedirs"* ]]
    then
        SKIPHOMEDIRS=1
    else
        SKIPHOMEDIRS=0
    fi

    if [ "${arg_list[0]}" == "system" ]
    then
        if [ "${arg_list[1]}" == "backup" ]
        then
            _msg_ "system backup [contains full system backup: users, user accounts]"
            full_system_backup
        elif [ "${arg_list[1]}" == "restore" ]
        then
            if [ "$(ls -1 $home_backups_path)" != "" ] && [ "$(ls -1 $system_backups_path)" != "" ]
            then
                _msg_ "system restore [contains fill system restore: users, user accounts]"
                system_restore
            else
                _msg_ "Backup files not found: $home_backups_path and/or $system_backups_path"
            fi
        else
            _msg_ "Unknown argument ${arg_list[1]} use: help for more information"
        fi
    elif [ "${arg_list[0]}" == "restore" ]
    then
        if [ "$(ls -1 $home_backups_path)" != "" ]
        then
            if [ "${arg_list[1]}" != "" ]
            then
                specific_user="${arg_list[1]}"
                _msg_ "user restore $specific_user [create subfolder for selected user and, restore last backup]"
                restore_user_home_folders "$specific_user"
            else
                _msg_ "users restore [create subfolder for every user and, restore last backup]"
                restore_user_home_folders
            fi
        else
            _msg_ "Backup not found: $home_backups_path"
        fi
    elif [ "${arg_list[0]}" == "backup" ]
    then
        _msg_ "users backup [ create users (home) backup ]"
        users_backup
    elif [ "${arg_list[0]}" == "struct" ]
    then
        show_backup_struct
    else
        echo -e "========================== backup_handler ===================================="
        echo -e "system backup\t\t- backup system [for migration]\n\t\t\twith all user homes, user accounts and ${extra_pathes[*]} extra folders, optional parameter: --skiphomedirs"
        echo -e "system restore\t\t- restore system [for migration]\n\t\t\twith all user homes, user accounts and ${extra_pathes[*]} extra folders, optional parameter: --skiphomedirs"
        echo -e "backup\t\t\t- backup home folders"
        echo -e "restore\t\t\t- restores every users last backup in subfolder under its own home dir"
        echo -e "restore <username>\t- restore a selected user last backup in subfolder under its own home dir"
        echo -e "struct\t\t\t-show actual backup archive structure"
    fi
}

#========================== MAIN ==========================#
main
write_status_file

exit "$ERRORS"

#unzip file:
#tar -xzf rebol.tar.gz
