#!/bin/bash

#source colors
source colors.bash

# message handler function
function message() {

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg"
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
            sudo apt install "$app"
            message "$app install ...DONE"
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
main
