#!/bin/bash

# Set setup env vars and aliases
MYPATHd="${BASH_SOURCE[0]}"
MYDIRd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
configtxt_path="/boot/config.txt"

function exitcode_handler() {
    local exitcode="$1"
    log_file="/var/log/dialog_log"
    if [ ! -e "$log_file" ]
    then
        sudo echo "" > "$log_file"
        sudo chgrp rpitools_user "$log_file"
        sudo chmod o+r "$log_file"
        sudo chmod g+rw "$log_file"
    fi
    case "$exitcode" in
        0)
            echo -e "action...[$exitcode]" >> "$log_file"
            ;;
        1)
            echo -e "Cancel was pressed! [$exitcode]" >> "$log_file"
            exit "$exitcode"
            ;;
        255)
            echo "ESC pressed." >> "$log_file"
            ;;
        *)
            echo -e "Dialog drops an error! [$exitcode]" >> "$log_file"
            exit "$exitcode"
            ;;
    esac
}

function dialog_menu() {
    local exitcode=0

    exec 4>&1
    result=$(dialog --clear --title "Choose display settings with rpitools" \
        --menu "Available displays:" 20 51 4 \
        "Elecrow-LCD5"  "5inch touch display - internal" \
        "standardHDMI" "general extarnal display" 2>&1 1>&4)
    exitcode=$?
    exec 4>&-

    exitcode_handler "$exitcode"
}

dialog_menu
if [ "$result" == "Elecrow-LCD5" ]
then
    echo -e "int $result"
    smartpatch "$configtxt_path" "${MYDIRd}/patches/internal_display.patch"
elif [ "$result" == "standardHDMI" ]
then
    echo -e "ext $result"
    smartpatch "$configtxt_path" "${MYDIRd}/patches/external_display.patch"
fi

