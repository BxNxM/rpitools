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

OS=$(uname)
if [ "$OS" == "Darwin" ]
then
    message "Use MacOS settings."
    glob_downloads_folder="/Users/$USER/Downloads/"
    glob_list_disks="$(diskutil list)"
    glob_bs_size="1m"
    glob_conv="sync"
elif [ "$OS" == "GNU/Linux" ] || [ "$OS" == "Linux"  ]
then
    message "Use Linux settings."
    glob_downloads_folder="/home/$USER/Downloads/"
    glob_list_disks="$(lsblk)"
    glob_bs_size="4M"
    glob_conv="fsync"
else
    message "This script work on Mac or Linux, this OS $OS is not supported!"
    exit 2
fi

elapsed_time "start"
# Copy raspbain image to temporary image folder
message "Search image..."
img_path=$(echo raspbian_img/*.img)
if [ ! -e "$img_path" ]
then
    img_in_downloads_folder="$(find $glob_downloads_folder -iname "*raspbian*lite*.img")"
    img_in_downloads_folder_list=($img_in_downloads_folder)
    if [ "${#img_in_downloads_folder_list[@]}" -gt 1 ]
    then
        message "Choose image:"
        for ((img_index=0; img_index<"${#img_in_downloads_folder_list[@]}"; img_index++))
        do
            echo -e "[$img_index] - ${img_in_downloads_folder_list[$img_index]}"
        done
        read image_index
        img_in_downloads_folder="${img_in_downloads_folder_list[$image_index]}"
    fi

    if [ -e "$img_in_downloads_folder" ]
    then
        echo -e "Copy $img_in_downloads_folder image to ${MYDIR_}/raspbian_img/"
        cp "$img_in_downloads_folder" "${MYDIR_}/raspbian_img/"
    else
        message "Image not found in ~/Downloads"
    fi
fi

# get image and make deployment to SD card
img_path_="$(echo raspbian_img/*.img)"
img_path="${MYDIR_}/${img_path_}"
if [ -e "$img_path" ]
then
    message "List drives: diskutil list / lsblk"
    echo -e "$glob_list_disks"

    message "Which drive want you use? example: /dev/disk<n> or /dev/sd<n>"
    read drive

    if [ -e "$drive" ]
    then
        if [ "$OS" == "Darwin" ]
        then
            message "Unmount drive: diskutil unmountDisk $drive"
            diskutil unmountDisk "$drive"
        else
            message "Unmount drive: umount $drive"
            umount "$drive"
        fi
        message "Deploy img to drive: sudo dd bs=1m if=$img_path of=$drive conv=$glob_conv"
        message "WARNING: please wait patiently!"
        sudo dd bs="$glob_bs_size" if="$img_path"  of="$drive" conv="$glob_conv"
        if [ "$?" -eq 0 ]
        then
            message "SUCCESS"
            echo -e "Remove temporary image file: $img_path"
            rm -f "$img_path"
            echo "$drive" > "${MYDIR_}/.drive"
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
