#!/bin/bash

ARGS_LIST=($@)
MYPATH="${BASH_SOURCE[0]}"
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

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ EXT CONF HANDLER LIB ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ EXT CONF HANDLER LIB ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

#########################################
#               FUNCTIONS               #
#########################################
function validate_execute_function() {
    local function_exec="$1"
    local av_functions="$(declare -F)"
    av_functions=$(echo $av_functions | sed 's|declare -f||g')

    if [ -z "$function_exec" ]
    then
        message "Missing argument validate_execute_function: function_exec [$function_exec]"
        exit 1
    fi

    if [[ "$av_functions" == *"$function_exec"* ]]
    then
        message "${GREEN}VALID${NC}: $function_exec"
    else
        message "${RED}INVALID${NC}: $function_exec"
        exit 2
    fi
}

function archive_factory_backup() {
    # INPUT: from path, to_folder
    local from_path="$1"
    local to_path="${2}$(basename $from_path).factory"
    local final_config="${2}$(basename $from_path).final"

    if [ -z "$from_path" ] || [ -z "$to_path" ]
    then
        message "Missing argument archive_factory_backup: from_path [$from_path] or to_path [$to_path]"
        exit 1
    fi

    if [ ! -f "$to_path" ]
    then
        if [ -f "$from_path" ]
        then
            message "Archive factory backup: $from_path -> $to_path"
            cp "$from_path" "$to_path"
        else
            message "File not exists: archive_factory_backup from_path: $from_path"
            exit 3
        fi
    else
        local is_diff="$(diff -q $from_path $to_path)"
        if [ "$?" -eq 0 ] && [ "$is_diff" == "" ]
        then
            message "$to_path factory config backup already exists."
        else
            if [ -f "$final_config" ]
            then
                message "$to_path factory config backup already exists."
                message "\t- custom config was already applied: $final_config"
            else
                message "$from_pat <-> $to_path DIFFERENT"
                message "Archive new factory backup: $from_path -> $to_path"
                cp -f "$from_path" "$to_path"
                message "${RED}[ERROR]${NC} Please recreate patch files based on the new factory config: $from_path -> $to_path"
                exit 255
            fi
        fi
    fi
}

function save_conf_permissions_meta() {
    local config_path="$1"
    local meta_file_folder="$2"
    local owner="$(stat -c '%U' $config_path)"
    local group="$(stat -c '%G' $config_path)"
    local permissions="$(stat -c '%a' $config_path)"

    message "$config_path : $owner : $group : $permissions"
}

#########################################
#               EXECUTION               #
#########################################
validate_execute_function "${ARGS_LIST[0]}"
eval "${ARGS_LIST[*]}"

