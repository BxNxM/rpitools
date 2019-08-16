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

service_template_path="${REPOROOT}/template/general_template.service"

rpitools_linux_user="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
set_service_conf="$($CONFIGHANDLER -s RGB_CONTROLLER -o set_service)"
service_name="rgb_led_controller.service"

function message() {
    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') [ SET SYSTEMD SERVICE ] $msg"
    fi
}

function change_parameter() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        is_set="$(sudo cat "$where" | grep -v grep | grep "$from")"
        message "sudo cat $where | grep -v grep | grep $from\nis_set: $is_set"
        message "$is_set"
        if [ "$is_set" != "" ]
        then
            message "${GREEN}Set parameter: $to  (from: $from) ${NC}"
            sudo sed -i 's|'"${from}"'|'"${to}"'|g' "$where"
        else
            message "${GREEN}Custom parameter $from not exists in $where ${NC}"
        fi
    fi
}

function create_service() {
    local service_description="rgb LED cotroller service"
    local exec_cmd="/usr/bin/python3 rgb_led_controller.py"
    local working_dir="/home/${rpitools_linux_user}/rpitools/gpio/rgb_led/bin/"
    local syslog_idf="rgb_led_controller"
    local user="${rpitools_linux_user}"

    message "Copy service template ${service_template_path} -> ${MYDIR}/${service_name}"
    cp "${service_template_path}" "${MYDIR}/${service_name}"

    message "Set servive temaplete"
    change_parameter "%DESCRIPTION%" "${service_description}" "${MYDIR}/${service_name}"
    change_parameter "%INTERPRETER_n_SCRIPTNAME%" "${exec_cmd}" "${MYDIR}/${service_name}"
    change_parameter "%SCRIPT_PATH%" "${working_dir}" "${MYDIR}/${service_name}"
    change_parameter "%SYSLOG_IDF%" "${syslog_idf}" "${MYDIR}/${service_name}"
    change_parameter "%USER%" "${user}" "${MYDIR}/${service_name}"
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
    service="${service_name}"
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
    echo -e "${service_name} service is required - turn on"
    if [ ! -e "/lib/systemd/system/${service_name}" ]
    then
        create_service
        message "COPY: ${MYDIR}/${service_name} -> /lib/systemd/system/${service_name}"
        sudo cp "${MYDIR}/${service_name}" "/lib/systemd/system/${service_name}"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/${service_name} is already exists"
        #function_demo
    fi

    if [ "$(systemctl is-active ${service_name})" == "inactive" ]
    then
        message "START SERVICE: sudo systemctl start ${service_name}"
        sudo systemctl start "${service_name}"
        check_exitcode "$?"
    else
        message "ALREADY RUNNING SERVICE: ${service_name}"
    fi

    if [ "$(systemctl is-enabled ${service_name})" == "disabled" ]
    then
        message "ENABLE SERVICE: sudo systemctl enable ${service_name}"
        sudo systemctl enable "${service_name}"
        check_exitcode "$?"
    else
        message "SERVICE IS ALREADY ENABLED: ${service_name}"
    fi

elif [ "$set_service_conf" == "False" ] || [ "$set_service_conf" == "false" ]
then
    if [ ! -e "/lib/systemd/system/${service_name}" ]
    then
        create_service
        message "COPY: ${MYDIR}/${service_name} -> /lib/systemd/system/${service_name}"
        sudo cp "${MYDIR}/${service_name}" "/lib/systemd/system/${service_name}"
        check_exitcode "$?"
    else
        message "/lib/systemd/system/${service_name} is already exists"
        #function_demo
    fi

    echo -e "dropbox halpage service is required - turn off"

    if [ "$(systemctl is-active ${service_name})" == "active" ]
    then
        message "STOP SERVICE: sudo systemctl stop ${service_name}"
        sudo systemctl stop "${service_name}"
        check_exitcode "$?"
    else
        message "SERVICE NOT RUNNING: ${service_name}"
    fi

    if [ "$(systemctl is-enabled ${service_name})" == "enabled" ]
    then
        message "DISABLE SERVICE: sudo systemctl disable ${service_name}"
        sudo systemctl disable "${service_name}"
        check_exitcode "$?"
    else
        message "SERVICE IS ALREADY DISBALED: ${service_name}"
    fi
else
    echo -e "dropbox halpage service is not requested"
fi
