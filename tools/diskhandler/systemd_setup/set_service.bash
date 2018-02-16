#!/bin/bash

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
    service="diskhandler.service"
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

if [ ! -e /lib/systemd/system/diskhandler.service ]
then
    message "COPY:/home/$USER/rpitools/tools/diskhandler/systemd_setup/diskhandler.service -> /lib/systemd/system/diskhandler.service"
    sudo cp /home/pi/rpitools/tools/diskhandler/systemd_setup/diskhandler.service /lib/systemd/system/diskhandler.service
    check_exitcode "$?"

    message "START SERICE: sudo systemctl start diskhandler.service"
    sudo systemctl start diskhandler.service
    check_exitcode "$?"

    message "ENABLE SERICE: sudo systemctl enable diskhandler.service"
    sudo systemctl enable diskhandler.service
    check_exitcode "$?"

    function_demo
else
    message "/lib/systemd/system/diskhandler.service is already exists:"
    function_demo
fi
