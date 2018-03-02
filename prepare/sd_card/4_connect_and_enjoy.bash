#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGAHNDLER="${MYDIR_}/../../autodeployment/bin/ConfigHandlerInterface.py"
CUSTOM_CONFIG="${MYDIR_}/../../autodeployment/config/rpitools_config.cfg"
username="pi"
hostname="$($CONFIGAHNDLER -s RPI_MODEL -o custom_hostname).local"
echo -e "$hostname"

echo -e "\n=======================  RPITOOLS INFORMATIONS =============================="
echo -e "ssh pi@raspberrypi.local or ${username}@${hostname}"
echo -e "[!] Firt reneme your pi with: sudo raspy-config (if not set automaticly)"
echo -e "=======================  RPITOOLS INFORMATIONS ==============================\n"
sleep 3

function smart_connect() {
    local user="$1"
    local host="$2"
    echo -e "Try to connect: ${user}@${host}"
    is_avaible_output="$(ping -c 2 ${host})"
    is_avaible="$?"
    if [ "$is_avaible" -eq 0 ]
    then
        ssh-keygen -R "${host}"
        echo -e "${host} host is avaible :)"
        ssh "${user}@${host}"
    else
        echo -e "${host} host is not avaible :("
    fi
}

smart_connect "pi" "raspberrypi.local"
smart_connect "$username" "$hostname"
