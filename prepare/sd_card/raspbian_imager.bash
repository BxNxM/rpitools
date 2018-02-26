#!/bin/bash

#source colors
MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MYDIR_}/../colors.bash
source ${MYDIR_}/../sub_elapsed_time.bash

# message handler function
function message() {
    local rpitools_log_path="${MYDIR_}/../../cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img deploy ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img deploy ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

if [ -z "$REPOROOT" ]
then
    OS=$(uname)
    if [ "$OS" == "GNU/Linux" ]
    then
        message "This script work on Mac, this OS $OS is not supported!"
        exit 1
    fi
else
    message "This script work on Mac, this OS $OS is not supported!"
    exit 2
fi

elapsed_time "start"
# Copy raspbain image to temporary image folder
img_in_downloads_folder=~/Downloads/*raspbain*lite*.img
if [ -e "$img_in_downloads_folder" ]
then
    echo -e "Copy $img_in_downloads_folder image to ${MYDIR_}/raspbian_img/"
    cp "$img_in_downloads_folder" ${MYDIR_}/raspbian_img/
fi

# get image and make deployment to SD card
img_path=$(echo raspbian_img/*.img)
if [ -e "$img_path" ]
then
    message "List drives: diskutil list"
    diskutil list

    message "Which drive want you use? example: /dev/disk<n>"
    read drive

    if [ -e "$drive" ]
    then
        message "Unmount drive: diskutil unmountDisk $drive"
        diskutil unmountDisk "$drive"
        message "Deploy img to drive: sudo dd bs=1m if=$img_path of=$drive conv=sync"
        message "WARNING: please wait patiently!"
        sudo dd bs=1m if="$img_path"  of="$drive" conv=sync
        if [ "$?" -eq 0 ]
        then
            message "SUCCESS"
            echo -e "Remove temporary image file: $img_path"
            rm -f "$img_path"
        else
            message "FAILED"
        fi
    else
        message "Invalid $drive drive"
    fi
    elapsed_time "stop"
else
    message "Image not found in $img_path"
    exit 1
fi
