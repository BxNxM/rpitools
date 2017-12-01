#!/bin/bash

#source colors
source colors.bash

# message handler function
function message() {

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${CYAN}[ img deploy ]${NC} $msg"
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
        else
            message "FAILED"
        fi
    else
        message "Invalid $drive drive"
    fi
else
    message "Image not found in $img_path"
    exit 1
fi
