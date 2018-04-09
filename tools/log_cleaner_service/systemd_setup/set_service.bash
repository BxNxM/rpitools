#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
set_service_conf="$($confighandler -s LOGROTATE -o service)"

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
    service="rpitools_logrotate.service"
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
    if [ ! -e "/lib/systemd/system/rpitools_logrotate.service" ]
    then
        message "COPY: ${MYDIR}/rpitools_logrotate.service -> /lib/systemd/system/rpitools_logrotate.service"
        sudo cp "${MYDIR}/rpitools_logrotate.service" "/lib/systemd/system/rpitools_logrotate.service"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/rpitools_logrotate.service is already exists"
        #function_demo
    fi

    if [ "$(systemctl is-active rpitools_logrotate)" == "inactive" ]
    then
        message "START SERICE: sudo systemctl start rpitools_logrotate.service"
        sudo systemctl start rpitools_logrotate.service
        check_exitcode "$?"
    else
        message "ALREADY RUNNING SERICE: rpitools_logrotate.service"
    fi

    if [ "$(systemctl is-enabled rpitools_logrotate)" == "disabled" ]
    then
        message "ENABLE SERICE: sudo systemctl enable rpitools_logrotate.service"
        sudo systemctl enable rpitools_logrotate.service
        check_exitcode "$?"
    else
        message "SERICE IS ALREADY ENABLED: rpitools_logrotate.service"
    fi

elif [ "$set_service_conf" == "False" ] || [ "$set_service_conf" == "false" ]
then
    if [ ! -e "/lib/systemd/system/rpitools_logrotate.service" ]
    then
        message "COPY: ${MYDIR}/rpitools_logrotate.service -> /lib/systemd/system/rpitools_logrotate.service"
        sudo cp "${MYDIR}/rpitools_logrotate.service" "/lib/systemd/system/rpitools_logrotate.service"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/rpitools_logrotate.service is already exists"
        #function_demo
    fi

    echo -e "dropbox halpage service is required - turn off"

    if [ "$(systemctl is-active rpitools_logrotate)" == "active" ]
    then
        message "STOP SERICE: sudo systemctl stop rpitools_logrotate.service"
        sudo systemctl stop rpitools_logrotate.service
        check_exitcode "$?"
    else
        message "SERICE NOT RUNNING: rpitools_logrotate.service"
    fi

    if [ "$(systemctl is-enabled rpitools_logrotate)" == "enabled" ]
    then
        message "DISABLE SERICE: sudo systemctl disable rpitools_logrotate.service"
        sudo systemctl disable rpitools_logrotate.service
        check_exitcode "$?"
    else
        message "SERICE IS ALREADY DISBALED: rpitools_logrotate.service"
    fi
else
    echo -e "dropbox halpage service is not requested"
fi
