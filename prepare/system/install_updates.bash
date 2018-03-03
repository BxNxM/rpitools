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
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_PURPLE}[ update ]${NC} $msg"
        if [ ! -z ${REPOROOT} ]
        then
            echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_PURPLE}[ update ]${NC} $msg" >> "$rpitools_log_path"
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

function update_grade_dits_clean() {
    message "CMD: sudo apt-get update --fix-missing"
    echo "Y" | sudo apt-get update --fix-missing

    message "CMD: sudo apt update"
    echo "Y" | sudo apt-get update

    message "CMD: sudo apt upgrade"
    echo "Y" | sudo apt-get upgrade

    message "CMD: sudo apt dist-upgrade"
    echo "Y" | sudo apt-get dist-upgrade

    message "CMD: sudo apt clean"
    echo "Y" | sudo apt-get clean
}

elapsed_time "start"
update_grade_dits_clean
elapsed_time "stop"
