#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
set_service_conf="$($confighandler -s INSTALL_OLED -o action)"

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
    service="oled_gui_core.service"
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
    echo -e "oled gui core service is required - turn on"
    if [ ! -e "/lib/systemd/system/oled_gui_core.service" ]
    then
        message "COPY: ${MYDIR}/oled_gui_core.service -> /lib/systemd/system/oled_gui_core.service"
        sudo cp "${MYDIR}/oled_gui_core.service" "/lib/systemd/system/oled_gui_core.service"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/oled_gui_core.service is already exists"
        #function_demo
    fi

    if [ "$(systemctl is-active oled_gui_core)" == "inactive" ]
    then
        message "START SERICE: sudo systemctl start oled_gui_core.service"
        sudo systemctl start oled_gui_core.service
        check_exitcode "$?"
    else
        message "ALREADY RUNNING SERICE: oled_gui_core.service"
    fi

    if [ "$(systemctl is-enabled oled_gui_core)" == "disabled" ]
    then
        message "ENABLE SERICE: sudo systemctl enable oled_gui_core.service"
        sudo systemctl enable oled_gui_core.service
        check_exitcode "$?"
    else
        message "SERICE IS ALREADY ENABLED: oled_gui_core.service"
    fi

elif [ "$set_service_conf" == "False" ] || [ "$set_service_conf" == "false" ]
then
    if [ ! -e "/lib/systemd/system/oled_gui_core.service" ]
    then
        message "COPY: ${MYDIR}/oled_gui_core.service -> /lib/systemd/system/oled_gui_core.service"
        sudo cp "${MYDIR}/oled_gui_core.service" "/lib/systemd/system/oled_gui_core.service"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/oled_gui_core.service is already exists"
        #function_demo
    fi

    echo -e "dropbox halpage service is required - turn off"

    if [ "$(systemctl is-active oled_gui_core)" == "active" ]
    then
        message "STOP SERICE: sudo systemctl stop oled_gui_core.service"
        sudo systemctl stop oled_gui_core.service
        check_exitcode "$?"
    else
        message "SERICE NOT RUNNING: oled_gui_core.service"
    fi

    if [ "$(systemctl is-enabled oled_gui_core)" == "enabled" ]
    then
        message "DISABLE SERICE: sudo systemctl disable oled_gui_core.service"
        sudo systemctl disable oled_gui_core.service
        check_exitcode "$?"
    else
        message "SERICE IS ALREADY DISBALED: oled_gui_core.service"
    fi
else
    echo -e "oled gui core (shield handler) service is not requested"
fi
