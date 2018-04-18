#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MYDIR_}/../colors.bash

OS=$(uname)
if [ "$OS" == "Darwin" ]
then
    message "Use MacOS settings."
    glob_list_disks="$(diskutil list)"
    glob_bs_size="4m"
elif [ "$OS" == "GNU/Linux" ] || [ "$OS" == "Linux"  ]
then
    message "Use Linux settings."
    glob_list_disks="$(lsblk)"
    glob_bs_size="4M"
else
    message "This script work on Mac or Linux, this OS $OS is not supported!"
    exit 2
fi

# message handler function
function message() {
    local rpitools_log_path="${MYDIR_}/../../cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img backup ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img backup ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

function make_backup() {
    local device="$1"
    local backup_image_path="${MYDIR_}/raspbian_bckp_$(date +"%Y_%m__%d_%H_%M").img.gz"

    message "CREATE BACKUP: sudo dd bs=$glob_bs_size if=$device | gzip > $backup_image_path"
    message "BE PATIENT, IT WILL TAKE SOME TIME [WARNING] DO NOT REMOVE SD CARD!!!"
    sudo dd bs="$glob_bs_size" if="$device" | gzip > "$backup_image_path"
    exit_code="$?"
    if [ "$exit_code" == 0 ]
    then
        message "\tSUCCESSFULL"
    else
        message "\tFAIL: $exit_code"
    fi
}


message "List drives: diskutil list"
echo -e "$glob_list_disks"

message "Which drive want you use? example: /dev/disk<n>"
read drive

make_backup "$drive"
