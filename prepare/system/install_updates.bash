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

update_retry=0
function repair_packages() {

    if [[ "$*" == *"E: dpkg was interrupted"* ]]
    then
        message "\tREPAIR $update_retry dpkg packages: sudo dpkg --configure -a"
        sudo dpkg --configure -a
        update_retry=$((update_retry + 1))
    fi
}

function update_grade_dits_clean() {
    message "CMD: sudo apt-get update --fix-missing"
    output_="$(echo 'Y' | sudo apt-get update --fix-missing 2>&1)"
    repair_packages "$output_"

    message "CMD: sudo apt-get update"
    output_="$(echo 'Y' | sudo apt-get update 2>&1)"
    repair_packages "$output_"

    message "CMD: sudo apt-get upgrade"
    output_="$(echo 'Y' | sudo apt-get upgrad 2>&1)"
    repair_packages "$output_"

    message "CMD: sudo apt-get dist-upgrade"
    output_="$(echo 'Y' | sudo apt-get dist-upgrade 2>&1)"
    repair_packages "$output_"

    message "CMD: sudo apt-get clean"
    output_="$(echo 'Y' | sudo apt-get clean 2>&1)"
    repair_packages "$output_"

    # WORKAROUND FOR: E: Unable to locate package <>
    message "CMD: sudo apt-get autoremove && sudo apt-get -f install && sudo apt-get update && sudo apt-get upgrade -y"
    output_="$(echo 'Y' | sudo apt-get autoremove && sudo apt-get -f install && sudo apt-get update && sudo apt-get upgrade -y 2>&1)"
    repair_packages "$output_"

    #message "CMD: sudo rpi-update"
    # sudo rpi-update
}

#elapsed_time "start"
update_grade_dits_clean
#elapsed_time "stop"
