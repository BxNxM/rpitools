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

source "${TERMINALCOLORS}"

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
    local rpitools_log_path="${RRPITOOLS_LOG}"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img backup ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img backup ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

function make_backup() {
    local device="$1"
    local backup_image_path="${MYDIR}/raspbian_bckp_$(date +"%Y_%m__%d_%H_%M").img.gz"

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
