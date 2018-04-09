#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
set_service_conf="$($confighandler -s EXTIPHANDLER -o set_service)"

function message() {
    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') [ SET SYSTEMD SERVICE ] $msg"
    fi
}

function check_exitcode() {
    local status="$1"
    if [ "$status" -ne 0 ]
    then
        message "ERROR: $status"
        exit 2
    fi
}

function function_demo() {
    service="dropbox_halpage.service"
    message "INFO about service (systemd)"
    message "systemctl status $service"
    message "systemctl is-active $service"
    message "systemctl is-enabled $service"
    message "systemctl is-failed $service"
    message "sudo systemctl enable $service"
    message "sudo systemctl disable $service"
    message "sudo systemctl start $service"
    message "sudo systemctl stop $service"
    message "sudo systemctl restart $service"
    message "More info: https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units"

}

if [ "$set_service_conf" == "True" ] || [ "$set_service_conf" == "true" ]
then
    echo -e "dropbox halpage service is required - turn on"
    if [ ! -e "/lib/systemd/system/dropbox_halpage.service" ]
    then
        message "COPY: ${MYDIR}/dropbox_halpage.service -> /lib/systemd/system/dropbox_halpage.service"
        sudo cp "${MYDIR}/dropbox_halpage.service" "/lib/systemd/system/dropbox_halpage.service"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/dropbox_halpage.service is already exists"
        #function_demo
    fi

    if [ "$(systemctl is-active dropbox_halpage)" == "inactive" ]
    then
        message "START SERICE: sudo systemctl start dropbox_halpage.service"
        sudo systemctl start dropbox_halpage.service
        check_exitcode "$?"
    else
        message "ALREADY RUNNING SERICE: dropbox_halpage.service"
    fi

    if [ "$(systemctl is-enabled dropbox_halpage)" == "disabled" ]
    then
        message "ENABLE SERICE: sudo systemctl enable dropbox_halpage.service"
        sudo systemctl enable dropbox_halpage.service
        check_exitcode "$?"
    else
        message "SERICE IS ALREADY ENABLED: dropbox_halpage.service"
    fi

elif [ "$set_service_conf" == "False" ] || [ "$set_service_conf" == "false" ]
then
    if [ ! -e "/lib/systemd/system/dropbox_halpage.service" ]
    then
        message "COPY: ${MYDIR}/dropbox_halpage.service -> /lib/systemd/system/dropbox_halpage.service"
        sudo cp "${MYDIR}/dropbox_halpage.service" "/lib/systemd/system/dropbox_halpage.service"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/dropbox_halpage.service is already exists"
        #function_demo
    fi

    echo -e "dropbox halpage service is required - turn off"

    if [ "$(systemctl is-active dropbox_halpage)" == "active" ]
    then
        message "STOP SERICE: sudo systemctl stop dropbox_halpage.service"
        sudo systemctl stop dropbox_halpage.service
        check_exitcode "$?"
    else
        message "SERICE NOT RUNNING: dropbox_halpage.service"
    fi

    if [ "$(systemctl is-enabled dropbox_halpage)" == "enabled" ]
    then
        message "DISABLE SERICE: sudo systemctl disable dropbox_halpage.service"
        sudo systemctl disable dropbox_halpage.service
        check_exitcode "$?"
    else
        message "SERICE IS ALREADY DISBALED: dropbox_halpage.service"
    fi
else
    echo -e "dropbox halpage service is not requested"
fi
