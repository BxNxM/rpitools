#!/bin/bash

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

CUSTOM_CONFIG="${REPOROOT}/autodeployment/config/rpitools_config.cfg"
username="pi"
hostname="$($CONFIGHANDLER -s GENERAL -o custom_hostname).local"
custom_pwd="$($CONFIGHANDLER -s SECURITY -o os_user_passwd)"
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
        ssh -o StrictHostKeyChecking=no "${user}@${host}"
    else
        echo -e "${host} host is not avaible :("
    fi
}

smart_connect "$username" "$hostname"
if [ "$is_avaible" -ne 0 ]
then
    smart_connect "pi" "raspberrypi.local"
fi
