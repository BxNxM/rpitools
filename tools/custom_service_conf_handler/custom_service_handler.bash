#!/bin/bash

######################################################
#               ARG FUNCTION FRAMEWORK               #
######################################################

ARGS_LIST=($@)
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AV_FUNCTIONS=""
FUNCTIONS_BLACKLIST=("validate_execute_function" "check_exitcode" "message" "change_parameter" "create_service")
PATCH_EXIT_CODE=0
# EXITCODES:
#       INPUT ERROR: 1
#       EXEC ERROR: 2
SERVICE_TEMPLATE_PATH="${MYDIR}/general_template.service"

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

##################################################
#               INTERNAL FUNCTIONS               #
##################################################
source "${TERMINALCOLORS}"

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_BLUE}[ CUSTOM SERVICE HANDLER ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_BLUE}[ CUSTOM SERVICE HANDLER ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

# GET FUNCTIONS IN THIOS ENV, FILDER WITH THE LOCAL DEFINES ONES - CREATE CALLABLE FUNCTION LIST
function validate_execute_function() {
    local function_exec="$1"
    AV_FUNCTIONS="$(declare -F)"
    AV_FUNCTIONS=$(echo $AV_FUNCTIONS | sed 's|declare -f||g')
    local AV_FUNCTIONS_FILTERED=""

    local av_func_list=($AV_FUNCTIONS)
    for func in ${av_func_list[@]}
    do
        if [ "$(cat $MYPATH | grep 'function '"$func"'()')" != "" ]
        then
            if [[ "${FUNCTIONS_BLACKLIST[*]}" != *"$func"* ]]
            then
                AV_FUNCTIONS_FILTERED+="$func "
            fi
        fi
    done
    AV_FUNCTIONS="${AV_FUNCTIONS_FILTERED}"

    if [ -z "$function_exec" ]
    then
        message "Missing argument validate_execute_function: function_exec [$function_exec]"
        exit 1
    fi

    if [[ "$AV_FUNCTIONS" == *"$function_exec"* ]]
    then
        message "${GREEN}VALID${NC}: $function_exec"
    else
        message "${RED}INVALID${NC}: $function_exec"
        exit 2
    fi
}

function help() {
    local av_func_list=(${AV_FUNCTIONS})
    message "HELP MESSAGE"
    for func in ${av_func_list[@]}
    do
        message "\t$func"
    done
}

#########################################
#               FUNCTIONS               #
#########################################

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
    local service_description="$1"      # service description
    local exec_cmd="$2"                 # exec comamnd
    local working_dir="$3"              # exec_cmd working dir
    local syslog_idf="$4"               # tag service in syslog
    local service_name="$5"             # service custom name
    local target_dir_path="$6"          # generated temaple service file path
    local service_user="$7"             # service user = linux user name

    message "Copy service template ${SERVICE_TEMPLATE_PATH} -> ${target_dir_path}/${service_name}"
    cp "${SERVICE_TEMPLATE_PATH}" "${target_dir_path}/${service_name}"

    message "Set servive temaplete: ${target_dir_path}/${service_name}"
    change_parameter "%DESCRIPTION%" "${service_description}" "${target_dir_path}/${service_name}"
    change_parameter "%INTERPRETER_n_SCRIPTNAME%" "${exec_cmd}" "${target_dir_path}/${service_name}"
    change_parameter "%SCRIPT_PATH%" "${working_dir}" "${target_dir_path}/${service_name}"
    change_parameter "%SYSLOG_IDF%" "${syslog_idf}" "${target_dir_path}/${service_name}"
    change_parameter "%USER%" "${service_user}" "${target_dir_path}/${service_name}"
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

function set_service() {
    # Parameters for create_service
    local arglist=($@)
    if [ "${#arglist[@]}" -lt 8 ]
    then
        message "set_service input arg ERROR, not enough input parameters: ${#arglist[@]}/8"
    fi
    local service_description="${1}"
    local exec_cmd="${2}"
    local working_dir="${3}"
    local syslog_idf="${4}"
    local service_name="${5}"
    local target_dir_path="${6}"
    local rpitools_linux_user="${7}"
    # Service activation
    local set_service_conf="${8}"

    message "${YELLOW}$service_name${NC}"
    message "\tservice_description: $service_description"
    message "\texec_cmd: $exec_cmd"
    message "\tworking_dir: $working_dir"
    message "\tsyslog_idf: $syslog_idf"
    message "\tservice_name: $service_name"
    message "\ttarget_dir_path: $target_dir_path"
    message "\trpitools_linux_user: $rpitools_linux_user"
    message "\tset_service_conf: $set_service_conf"

    if [ "$set_service_conf" == "True" ] || [ "$set_service_conf" == "true" ]
    then
        echo -e "${service_name} service is required - turn on"
        if [ ! -e "/lib/systemd/system/${service_name}" ]
        then
            create_service "${service_description}" "${exec_cmd}" "${working_dir}" "${syslog_idf}" "${service_name}" "${target_dir_path}" "${rpitools_linux_user}"
            message "COPY: ${target_dir_path}/${service_name} -> /lib/systemd/system/${service_name}"
            sudo cp "${target_dir_path}/${service_name}" "/lib/systemd/system/${service_name}"
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
            create_service "${service_description}" "${exec_cmd}" "${working_dir}" "${syslog_idf}" "${service_name}" "${target_dir_path}" "${rpitools_linux_user}"
            message "COPY: ${target_dir_path}/${service_name} -> /lib/systemd/system/${service_name}"
            sudo cp "${target_dir_path}/${service_name}" "/lib/systemd/system/${service_name}"
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
}

# Test
# Parameters for create_service
service_description="auto refresh transmission with new user ips"
exec_cmd="/bin/bash restart_transmission_w_ext_users.sh -loop"
working_dir="/home/${rpitools_linux_user}/rpitools/tools/auto_restart_transmission/"
syslog_idf="auto_restart_transmission"
service_name="auto_restart_transmission.service"
target_dir_path="${MYDIR}/../auto_restart_transmission/systemd_setup/"
rpitools_linux_user="$($CONFIGHANDLER -s GENERAL -o user_name_on_os)"
# Service activation
set_service_conf="$($CONFIGHANDLER -s TRANSMISSION -o auto_edit_whitelist)"

#set_service "$service_description" "$exec_cmd" "$working_dir" "$syslog_idf" "$service_name" "$target_dir_path" "$rpitools_linux_user" "$set_service_conf"

#########################################
#               EXECUTION               #
#########################################
validate_execute_function "${ARGS_LIST[0]}"
eval "${ARGS_LIST[*]}"
exit "$PATCH_EXIT_CODE"
