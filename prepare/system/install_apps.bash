#!/bin/bash

#source colors
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

source "${TERMINALCOLORS}"
source ${MYDIR}/../sub_elapsed_time.bash

was_installation=0
# optional program installations
transmission_installation="$($CONFIGHANDLER -s TRANSMISSION -o activate)"
apache_installation="$($CONFIGHANDLER -s APACHE -o activate)"

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
pymodulelist_pip=${REPOROOT}/template/python_moduls_pip.dat
installed_python_module=${REPOROOT}/cache/installed_pymodules.dat
installed_apps=${REPOROOT}/cache/installed_apps.dat
# initialize installed_apps.dat
if [ ! -e "$installed_apps" ]
then
    echo "" > "$installed_apps"
fi

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

function install_printout() {
    local app="$1"
    local exitcode="$2"

    if [ "$exitcode" -eq 0 ]
    then
        message "$app install ...DONE"
        echo -e "$app" >> "$installed_apps"
    else
        message "$app install ...FAILS"
    fi
}

function install_apps_secure() {
    local app="$1"
    if [ ! -z "$app" ]
    then
        output=$(command -v "$app")
        if [ -z "$output" ] && [ "$(cat $installed_apps | grep $app)" == "" ]   # grepping workaround for caca-utils, fail2ban, minidlna, etc.
        then
            if [ "$app" == "samba" ] || [ "$app" == "apache2" ] || [ "$app" == "php" ] || [ "$app" == "nfs" ]
            then
                apps_exception "$app"
            else
                echo -e "Install app: $app"
                echo "Y" | sudo apt-get install "$app"
                install_printout "$app" "$?"
                was_installation=1
            fi
        else
           message "$app is already installed"
        fi
    fi
}

function apps_exception() {
    local app="$1"
    if [ "$app" == "samba" ]
    then
        echo -e "Install app: samba samba-common-bin"
        echo "Y" | sudo apt-get install samba samba-common-bin
        install_printout "samba samba-common-bin" "$?"
        was_installation=1
    fi

    if [ "$app" == "apache2" ]
    then
        echo -e "install app: apache2 -y"
        echo "y" | sudo apt-get install apache2 -y
        install_printout "apache2 -y" "$?"
        was_installation=1
    fi

    if [ "$app" == "php" ]
    then
        echo -e "install app: sudo apt-get install php libapache2-mod-php -y"
        echo "y" | sudo apt-get install php libapache2-mod-php -y
        install_printout "php libapache2-mod-php -y" "$?"
        was_installation=1
    fi

    if [ "$app" == "nfs" ]
    then
        echo -e "install app: sudo apt-get install nfs-common nfs-server -y"
        echo "y" | sudo apt-get install nfs-common nfs-server -y
        install_printout "nfs-common nfs-server -y" "$?"
        was_installation=1
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
            echo "Y" | sudo apt-get install "$app"
            if [ "$?" == 0 ]
            then
                message "$app install python module ...DONE"
                echo -e "$app" >> "$installed_python_module"
            else
                message "$app install python module ...FAILED"
            fi
            was_installation=1
        else
           message "$app python module is already installed"
        fi
    fi
}

function install_pymodule_pip_secure() {
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
            echo -e "Install python module with pip and pip3: $app"
            echo "Y" | pip3 install "$app"
            local exitcode_pip3="$?"
            echo "Y" | pip install "$app"
            if [ "$?" == 0 ] || [ "$exitcode_pip3" == 0 ]
            then
                message "$app install python module with pip...DONE"
                echo -e "$app" >> "$installed_python_module"
            else
                message "$app install python module with pip...FAIL"
            fi
            was_installation=1
        else
           message "$app python module (with pip) is already installed"
        fi
    fi
}

function main() {
    # install apps
    fileReader "$applist"
    for current_app in "${lineS[@]}"
    do
        # skip transmission installation - based on rpitools config
        if [ "$current_app" == "transmission-daemon" ]
        then
            if [ "$(echo "$transmission_installation" | tr '[:upper:]' '[:lower:]')" != "true" ]; then message "Skip transmission installation..."; continue; fi
        fi
        # skip apache installation - based on rpitools config
        if [ "$current_app" == "apache2" ]
        then
            if [ "$(echo "$apache_installation"  | tr '[:upper:]' '[:lower:]')" != "true" ]; then message "Skip apache installation..."; continue; fi
        fi
        install_apps_secure "$current_app"
    done

    # install python modules
    fileReader "$pymodulelist"
    for current_modul in "${lineS[@]}"
    do
        install_pymodule_secure "$current_modul"
    done

    # install python modules with pip
    fileReader "$pymodulelist_pip"
    for current_modul_pip in "${lineS[@]}"
    do
        install_pymodule_pip_secure "$current_modul_pip"
    done
}

#elapsed_time "start"
main
if [ "$was_installation" -eq 1 ]
then
    if [ ! -e "${REPOROOT}/cache/.instantiation_done" ]
    then
        message "After program installations, execute: sudo reboot"
        . "${REPOROOT}/tools/cache_restore_backup.bash" "backup"
        sudo reboot
    else
        message "After program installations good to restart the system: sudo reboot"
    fi
fi
#elapsed_time "stop"
