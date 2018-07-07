#!/bin/bash

#source colors
MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MYDIR_}/../colors.bash
source ${MYDIR_}/../sub_elapsed_time.bash

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ install vnc ]${NC} $msg"
        if [ ! -z "${REPOROOT}" ]
        then
            echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ install vnc ]${NC} $msg" >> "$rpitools_log_path"
        fi
    fi
}

# check we are sourced up
if [ -z "$REPOROOT" ]
then
    message "Please ${RED}source rpitools/setup${NC} before use these script!"
    exit 1
else
    if [ "$OS" != "GNU/Linux" ]
    then
        message "This script work on raspbian, this OS $OS is not supported!"
        exit 2
    fi
fi

is_installed_file_indicator=${REPOROOT}/cache/.vnc_installed

function install_vnc() {

    if [ -e "$is_installed_file_indicator" ]
    then
        message "vnc is already installed.\nfor more info about vnc: https://www.raspberrypi.org/documentation/remote-access/vnc/"
    else
        message "update: sudo apt-get update"
        sudo apt-get update
        message "install: sudo apt-get install realvnc-vnc-server realvnc-vnc-viewer"
        echo "Y" | sudo apt-get install realvnc-vnc-server realvnc-vnc-viewer
        message "For more info: https://www.raspberrypi.org/documentation/remote-access/vnc/"
        echo "$(date) PIXEL was installed" > "$is_installed_file_indicator"

        message "REBOOT..."
        sleep 3
        sudo reboot
    fi
}

#elapsed_time "start"
install_vnc
#elapsed_time "stop"
