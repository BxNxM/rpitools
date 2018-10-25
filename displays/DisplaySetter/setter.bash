#!/bin/bash

# Set setup env vars and aliases
MYPATHd="$(readlink -f $0)"
MYDIRd="$( dirname $MYPATHd)"
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
        --menu "Available displays:" 20 65 4 \
        "Elecrow-LCD5"  "5inch touch display - internal" \
        "standardHDMI" "general extarnal display" \
        "Elecrow-LCD5driver_install" "driver download and install" 2>&1 1>&4)
    exitcode=$?
    exec 4>&-

    exitcode_handler "$exitcode"
}

dialog_menu
if [ "$result" == "Elecrow-LCD5" ]
then
    echo -e "internal display settigs $result"
    smartpatch "$configtxt_path" "${MYDIRd}/patches/internal_display.patch"
elif [ "$result" == "standardHDMI" ]
then
    echo -e "external display settigs $result"
    smartpatch "$configtxt_path" "${MYDIRd}/patches/external_display.patch"
elif [ "$result" == "Elecrow-LCD5driver_install" ]
then
    pushd "${MYDIRd}/../"
        if [ ! -d "Elecrow-LCD5" ]
        then
            echo -e "download Elecrow-LCD5 driver"
            "${MYDIRd}/Elecrow-LCD5_driver_downloader.bash"
        else
            echo -e "Elecrow-LCD5 driver already exists."
        fi
        sudo ./Elecrow-LCD5/Elecrow-LCD5
    popd
fi
