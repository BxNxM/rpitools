#!/bin/bash

#source colors
source prepare_sd/colors.bash
source prepare_sd/sub_elapsed_time.bash
was_installation=0

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg" >> "$rpitools_log_path"
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

# start install stuff
applist=${REPOROOT}/template/programs.dat

function fileReader {
    lineS=()

    if [ -e "$1" ]
    then
        while read line || [ -n "$line" ]
        do
             lineS+=($line)
        done < "$1"
    else
            echo -e "$1 NOT EXISTS!"
    fi
}

function install_secure() {
    local app="$1"
    if [ ! -z "$app" ]
    then
        output=$(command -v "$app")
        if [ -z "$output" ]
        then
            echo "Y" | sudo apt install "$app"
            message "$app install ...DONE"
            was_installation=1
        else
           message "$app is already installed"
        fi
    fi
}

function main() {
    fileReader "$applist"
    for current_app in "${lineS[@]}"
    do
        install_secure "$current_app"
    done
}
elapsed_time "start"
main
if [ "$was_installation" -eq 1 ]
then
    message "After program installations good to make a reboot -> sudo reboot"
fi
elapsed_time "stop"
