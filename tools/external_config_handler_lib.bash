#!/bin/bash

ARGS_LIST=($@)
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AV_FUNCTIONS=""
FUNCTIONS_BLACKLIST=("validate_execute_function" "message" "change_parameter_in_file" "patch_exit")
PATCH_EXIT_CODE=0
# EXITCODES:
#       INPUT ERROR: 1
#       EXEC ERROR: 2


#################################
#     CONFIG FILES STRUCTURE    #
#################################

# STORED
# .factory              - saves and check factory config/settings - automatic
# .finaltemplate        - final template file with placeholsers - manual

# GENERATED
# .data                 - data for fill placeholders: syntax: {placeholder_name}=value
# .final                - .finaltemplate filled placeholders
# .finalpatch           - .final + .factory diff

# ACTION: execute .finalpatch on original factory settings
#################################

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

function change_parameter_in_file() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        is_set="$(sudo cat "$where" | grep -v grep | grep "$from")"
        #message "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        #message "$is_set"
        if [ "$is_set" != "" ]
        then
            message "${GREEN}Set parameter: $to  (from: $from) ${NC}"
            sudo sed -i 's|'"${from}"'|'"${to}"'|g' "$where"
            if [ "$?" -ne 0 ]
            then
                message "Replace was failed: $from -> $to in $where"
            fi
        else
            message "${GREEN}Custom parameter $to already set in $where ${NC}"
        fi
    fi
}

function patch_exit() {
    local exitcode="$1"
    PATCH_EXIT_CODE=$((PATCH_EXIT_CODE+exitcode))
    message "[WARNING] execution error in $(basename $MYPATH) ERROR_CODE[$exitcode]: [$PATCH_EXIT_CODE]"
    exit "$PATCH_EXIT_CODE"
}

#########################################
#         EXTERNAL FUNCTIONS            #
#########################################
function archive_factory_backup() {
    # INPUT: from path, to_folder
    local from_path="$1"
    local to_path="${2}$(basename $from_path).factory"
    local final_path="${2}$(basename $from_path).final"
    local final_template_path="${2}$(basename $from_path).finaltemplate"

    if [ -z "$from_path" ] || [ -z "$to_path" ]
    then
        message "Missing argument archive_factory_backup: from_path [$from_path] or to_path [$to_path]"
        patch_exit 1
    fi

    # Copy factory settings if not exists -- initiate
    if [ ! -f "$to_path" ]
    then
        message "Archive factory backup: $from_path -> $to_path"
        if [ -f "$from_path" ]
        then
            cp "$from_path" "$to_path"
        else
            message "File not exists: archive_factory_backup from_path: $from_path"
            patch_exit 1
        fi
    else
        message "$to_path already exists."
    fi

    # in case of final not exists - orig and stored factory setting sgould be the same
    if [ ! -f ${final_path} ]
    then
        local diff_factorys="$(diff -q $from_path $to_path)"
        if [ "$?" -ne 0 -o "$diff_factorys" != "" ]
        then
            message "Factory and stored factory settings was changed, please modify manually: $diff_factorys"
            message "\tCheck stored and orig factory diffs:\n\tvimdiff $to_path $from_path"
            message "\tThen modify the finaltemplate:\n\tvimdiff $to_path $final_template_path"
            patch_exit 2
        fi
    fi
}

function create_data_file() {
    local data_file_path="$1"
    local mode="$2"
    local placeholder="$3"
    local value="$4"

    if [ -z "$data_file_path" ]
    then
        message "Data file path was not provided: $data_file_path"
        patch_exit 1
    elif [[ "$data_file_path" != *".data" ]]
    then
        message "WARNING: naming convension, data file should have .data extension"
    fi
    if [ "$mode" != "init" -a "$mode" != "add" ]
    then
        message "Ivalid create_data_file mode: $mode [init|add]"
        patch_exit 1
    fi

    if [ -z "$placeholder" -o -z "$value" ]
    then
        message "placehodler: [$placeholder] or value: [$value] missing"
        patch_exit 1
    fi

    message "Create data file fregment: [$mode] ${placeholder}=${value} -> $data_file_path"

    if [ "$mode" == "init" ]
    then
        echo "${placeholder}=${value}" > "$data_file_path"
    else
        echo "${placeholder}=${value}" >> "$data_file_path"
    fi
}

function create_final() {
    local finaltemplate_path="$1"
    local data_path="$2"
    local final_path="${finaltemplate_path%.*}.final"

    if [ ! -f "$data_path" -o ! -f "$finaltemplate_path" ]
    then
        message "data_path [$data_path] and/or finaltemplate_path [$finaltemplate_path] nor exists"
        patch_exit 1
    fi

    if [[ "$finaltemplate_path" != *".finaltemplate" ]]
    then
        message "Please provide .finaltemplate file for generation .final"
        patch_exit 1
    fi

    message "Copy $finaltemplate_path to $final_path"
    cp -f "$finaltemplate_path" "$final_path"

    message "Apply data on $final_path"
    while IFS= read -r line || [ -n "$line" ]
    do
        local exitcode=0
        local placeholder=$(echo "$line" | cut -d'=' -f1)
        exitcode=$((exitcode+$?))
        local value=$(echo "$line" | cut -d'=' -f2)
        exitcode=$((exitcode+$?))

        if [ "$exitcode" -eq 0 ]
        then
            echo -e "\treplace all: $placeholder -> $value in $final_path"
            change_parameter_in_file "$placeholder" "$value" "$final_path"
        fi
    done < "$data_path"
}

function create_patch() {
    local factory_path="$1"
    local final_path="$2"
    local patch_path="${final_path%.*}.patch"

    message "Create patch: diff -u $factory_path $final_path > $patch_path"
    diff -u "$factory_path" "$final_path" > "$patch_path"
    if [ -f "$patch_path" ]
    then
        message "Patch was created successfuly."
    else
        message "Patch create failed"
        patch_exit 2
    fi
}

function apply_patch() {
    local origin_file="$1"
    local patch_file="$2"
    local orig_bak="$(dirname $patch_file)/$(basename $origin_file).bak"

    if [ ! -z "${origin_file}" -a ! -z ${patch_file} ]
    then
        if [ ! -f "${origin_file}" ]
        then
            message "${origin_file} not exists!"
            patch_exit 1
        fi
        if [ ! -e "${patch_file}" ]
        then
            message "${patch_file} not exists!"
            patch_exit 1
        fi
        if [[ "${patch_file}" != *".patch"* ]]
        then
            message "${patch_file} not a patch file!"
            patch_exit 1
        fi
    else
        message "apply_patch() Input error! [1] file [2] patch file"
        patch_exit 1
    fi

    message "Create config backup before patch: $origin_file -> $orig_bak"
    cp -f "$origin_file" "$orig_bak"

    sudo patch -p0 -N --dry-run --silent "$origin_file" "$patch_file" 2>/dev/null
    exit_code="$?"
    if [ "$exit_code" -eq 0 ]
    then
        message "Patch is needed."
        message "sudo bash -c \"patch $origin_file $patch_file\""
        sudo bash -c "patch $origin_file $patch_file"
        if [ "$?" -ne 0 ]
        then
            patch_exit 2
        fi
    else
        message "Error under applying patch"
        patch_exit 2
    fi

    diff -q "$orig_bak" ""$origin_file""
    if [ "$?" -eq 0 ]
    then
        message "CONFIG WAS NOT MODIFIED"
    else
        message "CONFIG WAS MODIFIED"
    fi
}

function patch_workflow() {
    local factory_config_path="$1"
    local local_config_dir_path="$2"

    local final_template_name="$3"
    local data_name="$4"
    local final_config_name="$5"
    local patch_name="$6"

    # archive factory config
    message "############################"
    message "# [1] SAVE FACTORY CONFIG  #"
    message "############################"
    archive_factory_backup "$factory_config_path" "$local_config_dir_path"

    # Create .final
    message "############################"
    message "# [2] CREATE FINAL CONFIG  #"
    message "############################"
    create_final "${local_config_dir_path}/$final_template_name" "${local_config_dir_path}/$data_name"

    # Create patch
    message "############################"
    message "#    [3] CREATE PATCH      #"
    message "############################"
    create_patch "$factory_config_path" "${local_config_dir_path}/$final_config_name"

    # Apply patch
    message "############################"
    message "#      [4] APPLY PATCH     #"
    message "############################"
    apply_patch "$factory_config_path" "${local_config_dir_path}/$patch_name"

    if [ "$PATCH_EXIT_CODE" -eq 0 ]
    then
        message "\t[${GREEN}OK${NC}]"
    else
        message "\t[${RED}ERR${NC}]"
    fi

    message "RESULT: $factory_config_path"
}

#########################################
#               EXECUTION               #
#########################################
validate_execute_function "${ARGS_LIST[0]}"
eval "${ARGS_LIST[*]}"
exit "$PATCH_EXIT_CODE"

