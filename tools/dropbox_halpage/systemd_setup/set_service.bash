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
    echo -e "dropbox halpage service is required"
    if [ ! -e "/lib/systemd/system/dropbox_halpage.service" ]
    then
        message "COPY: ${MYDIR}/dropbox_halpage.service -> /lib/systemd/system/dropbox_halpage.service"
        sudo cp "${MYDIR}/dropbox_halpage.service" "/lib/systemd/system/dropbox_halpage.service"
        check_exitcode "$?"

        message "START SERICE: sudo systemctl start dropbox_halpage.service"
        sudo systemctl start dropbox_halpage.service
        check_exitcode "$?"

        message "ENABLE SERICE: sudo systemctl enable dropbox_halpage.service"
        sudo systemctl enable dropbox_halpage.service
        check_exitcode "$?"

        #function_demo
    else
        message "/lib/systemd/system/dropbox_halpage.service is already exists"
        #function_demo
    fi
else
    echo -e "dropbox halpage service is not requested"
fi
