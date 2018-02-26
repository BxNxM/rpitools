#!/bin/bash

#source colors
MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MYDIR_}/../colors.bash
source ${MYDIR_}/../sub_elapsed_time.bash
was_installation=0

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg"
        if [ ! -z "${REPOROOT}" ]
        then
            echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ appinstall ]${NC} $msg" >> "$rpitools_log_path"
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

# start install stuff
applist=${REPOROOT}/template/programs.dat
pymodulelist=${REPOROOT}/template/python_moduls.dat
installed_python_module=${REPOROOT}/cache/installed_pymodules.dat

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

function install_apps_secure() {
    local app="$1"
    if [ ! -z "$app" ]
    then
        output=$(command -v "$app")
        if [ -z "$output" ]
        then
            echo -e "Install app: $app"
            echo "Y" | sudo apt install "$app"
            message "$app install ...DONE"
            was_installation=1
        else
           message "$app is already installed"
        fi
    fi
}

function install_pymodule_secure() {
    local app="$1"
    if [ ! -f "$installed_python_module" ]
    then
        echo -e "" > "$installed_python_module"
    fi

    if [ ! -z "$app" ]
    then
        output=$(cat $installed_python_module | grep  "$app")
        if [ -z "$output" ]
        then
            echo -e "Install python module: $app"
            echo "Y" | sudo apt install "$app"
            echo -e "$app" >> "$installed_python_module"
            message "$app install python module ...DONE"
            was_installation=1
        else
           message "$app python module is already installed"
        fi
    fi
}

function main() {
    fileReader "$applist"
    for current_app in "${lineS[@]}"
    do
        install_apps_secure "$current_app"
    done

    fileReader "$pymodulelist"
    for current_modul in "${lineS[@]}"
    do
        install_pymodule_secure "$current_modul"
    done
}
elapsed_time "start"
main
if [ "$was_installation" -eq 1 ]
then
    message "After program installations good to make a reboot -> sudo reboot"
fi
elapsed_time "stop"
