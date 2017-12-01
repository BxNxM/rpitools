#!/bin/bash

#source colors
source colors.bash

# message handler function
function message() {

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_PURPLE}[ update ]${NC} $msg"
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
    message "CMD: sudo apt update"
    echo "Y" | sudo apt update

    message "CMD: sudo apt upgrade"
    echo "Y" | sudo apt upgrade

    message "CMD: sudo apt dist-upgrade"
    echo "Y" | sudo apt dist-upgrade

    message "CMD: sudo apt clean"
    echo "Y" | sudo apt clean
}

update_grade_dits_clean
