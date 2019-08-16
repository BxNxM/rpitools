#!/bin/bash

# HANDLE INPUT ARGUMENTS
ARG_LIST=($@)
VERBOSE=0
SKIP_VALIDATION=0
FORCE=0
PROGRESS=0
for arg in "${ARG_LIST[@]}"
do
if [ "${#ARG_LIST[@]}" -gt 0 ]
then
    case "$arg" in
    "-v" | "--verbose")
        VERBOSE=1
        ;;
    "-s" | "--skipvalidation")
        SKIP_VALIDATION=1
        ;;
    "-f" | "--force")
        FORCE=1
        ;;
    "-d" | "--dump")
        rpienv_links=($(find ./ -iname "*.rpienv" -type f | grep 'link'))
        rpienv_adaptors=($(find ./ -iname "*.rpienv" -type f | grep -v 'link'))
        echo -e "RPIENV LINKS [${#rpienv_links[@]}]:"
        for k in ${rpienv_links[@]}; do echo -e "\t$k"; done
        echo -e "RPIENV ADAPTORS [${#rpienv_adaptors[@]}]:"
        for k in ${rpienv_adaptors[@]}; do echo -e "\t$k"; done
        ;;
    "-p" | "--progress")
        PROGRESS=1
        ;;
    *)
        echo -e "### RPITOOLS ENVIRONMENT GENERATOR ###"
        echo -e "-v | --verbose\t- print log messages to console"
        echo -e "-s | --skipvalidation\t- skip env validation"
        echo -e "-f | --force\t- force recreate env"
        echo -e "-d | --dump\t- dump *.rpienv files"
        echo -e "-p | --process\t- process indicator"
        echo -e ""
        echo -e "USAGE[CASE 1]:"
        echo -e "1. Create config file next to the script to expose"
        echo -e "<ENV/alias name>.rpienv       - replace <>"
        echo -e "2. Content of the rpienv config:"
        echo -e "SCRIPT=<foo.bash>             - replace <> exposed script name"
        echo -e "PROP=(\"env\" \"alias\")     - mode: env and/or alias"
        echo -e ""
        echo -e "USAGE[CASE 2]:"
        echo -e "1. Create config file next to the script where you want to use ENV VARS"
        echo -e "link.rpienv"
        echo -e "[i] if you don't want to expose any script but, ENV link needed"
        echo -e ""
        echo -e "THE CASE 1 and CASE 2 *.rpienv pathes automatically get .rpienv sourceable"
        echo -e "scipt what gets the proper environment back."
    esac
fi
done

# RPIENV NAME
RPIENV_BASH="rpienv.bash"
# GET REPOROOT
# 1. if we are in the repo
REPOROOT="$(git rev-parse --show-toplevel 2>>/dev/null)"
if [ "$?" -ne 0 ]
then
    # if we are outside of the repo
    REPOROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
fi
# validation
if [ ! -f "${REPOROOT}/${RPIENV_BASH}" ] || [ -L "${REPOROOT}/${RPIENV_BASH}" ]
then
    # if rpienv source was a symlink outside of the repo
    REPOROOT="$(find "/home/$USER" -name ${RPIENV_BASH} -type f 2>/dev/null)"
    REPOROOT="$(dirname "$REPOROOT")"
    # In case of absolute new shell execution (python subprocess) should search like this
    if [ ! -f "${REPOROOT}/${RPIENV_BASH}" ] || [ -L "${REPOROOT}/${RPIENV_BASH}" ]
    then
        REPOROOT="$(find "/home/" -name ${RPIENV_BASH} -type f 2>/dev/null)"
        REPOROOT="$(dirname "$REPOROOT")"
    fi
fi

# ENV FILE CACHE
ENV_CACHE_PATH="${REPOROOT}/cache/rpienv"
if [ ! -f "$ENV_CACHE_PATH" ]
then
    echo -n "" > "$ENV_CACHE_PATH"
fi
ENV_CACHE_PATH_INITIALIZED=0
# ALIAS CACHE PATH
ALIAS_CACHE_PATH="${REPOROOT}/cache/rpialiases"
if [ ! -f "$ALIAS_CACHE_PATH" ]
then
    echo -n "" > "$ALIAS_CACHE_PATH"
fi
# RPITOOLS SYS LOG
RRPITOOLS_LOG="${REPOROOT}/cache/rpitools.log"
if [ ! -f "$RRPITOOLS_LOG" ]
then
    echo -n "" > "$RRPITOOLS_LOG"
fi
# USER
USER="$USER"
# HOSTNAME
HOSTNAME="$HOSTNAME"
# BASE_ENV_LIST
BASE_ENV_LIST=("ENV_CACHE_PATH" "REPOROOT" "RRPITOOLS_LOG" "ALIAS_CACHE_PATH" "USER" "HOSTNAME")
# IGNORE PATH CHECK
IGNORE_PATH_CHECK=("DEVICE" "OS" "USER" "HOSTNAME")
# VALIDATION STATE - true:0 - false:>0
VALIDATION=0
# INTERFACE INDICATOR
INTERFACE_INDICATOR="*.rpienv"
# ENV PROPERTY LISTS
ENV_PROP_LIST=(${BASE_ENV_LIST[@]})
ALIAS_PROP_LIST=()
# SEARCHED .rpienv interfaces list
RPIENV_INTERFACES=()

__PROCESS_I=0
function progress_indicator() {
    local spin=("-" "\\" "|" "/")
    echo -ne "\b${spin[$__PROCESS_I]}"
    __PROCESS_I=$((__PROCESS_I+1))
    echo -ne "\b"

    if [ "$__PROCESS_I" -gt "${#spin[@]}" ]
    then
        __PROCESS_I=0
    fi
}

function console() {
    local msg="$*"
    if [ "$VERBOSE" -eq 1 ]
    then
        echo -e "[ ENV ] $msg"
        echo -e "[ ENV ] $msg" >> "$RRPITOOLS_LOG"
    else
        echo -e "[ ENV ] $msg" >> "$RRPITOOLS_LOG"
    fi
    if [ "$PROGRESS" -eq 1 ]
    then
        progress_indicator
    fi
}

function addenv() {
    echo "$*" >> "$ENV_CACHE_PATH"
}

function addalias() {
    echo "$*" >> "$ALIAS_CACHE_PATH"
}

function __elapsed_time() {
    local cmd="$1"
    if [ "$cmd" == "start" ]
    then
        SECONDS=0
    elif [ "$cmd" == "stop" ]
    then
        console "ELAPSED TIME: $SECONDS sec"
    fi
}

function validate() {

    local var_name=""
    local var_path=""

    # VALIDATE BASE PATHES
    for eenv in "${BASE_ENV_LIST[@]}"
    do
        if [[ -e "${!eenv}" ]] || [[ "${IGNORE_PATH_CHECK[*]}" == *" ${eenv}"* ]] || [[ "${IGNORE_PATH_CHECK[*]}" == *"${eenv} "* ]]
        then
            console "[ VALID ] $eenv ${!eenv}"
        else
            console "[ INVALID ] $eenv ${!eenv}"
            if [ "$eenv" == "ENV_CACHE_PATH" ]
            then
                ENV_CACHE_PATH_INITIALIZED=1
            fi
            VALIDATION=$((VALIDATION+1))
        fi
    done

    # BASE ENV INVALID IGNORE SKIP_VALIDATION
    if [ "$VALIDATION" -ne 0 ] && [ "$SKIP_VALIDATION" -eq 1 ]
    then
        SKIP_VALIDATION=0
    fi

    # VALIDATE ENV FILE
    if [ -e "$ENV_CACHE_PATH" ] && [ "$SKIP_VALIDATION" -eq 0 ]
    then
        while IFS= read -r line || [[ -n "$line" ]]
        do
            if [[ "$line" == *"="* ]]
            then
                if [[ "$line" == *"export"* ]]
                then
                    var_name="$(echo "$line" | cut -d' ' -f2 | cut -d'=' -f1)"
                    var_path="$(echo "$line" | cut -d' ' -f2 | cut -d'=' -f2)"
                else
                    var_name="$(echo "$line" | cut -d'=' -f1)"
                    var_path="$(echo "$line" | cut -d'=' -f2)"
                fi

                if [[ "$var_path" == *"'"* ]]
                then
                    var_path=$(echo "$var_path" | cut -d"'" -f2)
                fi

                if [ -e "$var_path" ]
                then
                    console "[ VALID ] ${var_name}=$var_path"
                else
                    if [[  "${IGNORE_PATH_CHECK[*]}" == *"$var_name"* ]]
                    then
                        console "[ VALID ] [SKIP PATH VALIDATION] ${var_name}=$var_path"
                    else
                        console "[ INVALID ] ${var_name}=$var_path"
                        VALIDATION=$((VALIDATION+1))
                    fi
                fi
            fi
        done < "$ENV_CACHE_PATH"
    fi
}

function create() {

    console "[RE]CREATE ENV [$VALIDATION]"
    local interface_dot_ife_list=($(find "$REPOROOT" -type f -name "$INTERFACE_INDICATOR"))
    RPIENV_INTERFACES=(${interface_dot_ife_list[@]})
    __init_and_create_base_env
    for ife in "${RPIENV_INTERFACES[@]}"
    do
        if [ "$(cat "$ife" | grep 'SCRIPT')" != "" ] && [ "$(cat "$ife" | grep 'PROP')" != "" ]
        then
            local ife_dir_path="$(dirname "$ife")"
            local ife_name="$(echo $(basename "$ife") | cut -d'.' -f1)"
            local ife_script="$(source "$ife" && echo "$SCRIPT")"
            local ife_prop="$(source "$ife" && echo "${PROP[@]}")"
            console "[ INTERFACE ]"
            __add_to_prop_lists "$ife_name" "$ife_prop"
            __create_env "$ife_name" "$ife_dir_path/$ife_script"
            __create_aliases "$ife_name" "$ife_dir_path/$ife_script"
        elif [  "$(basename $ife)" == "link.rpienv"  ]
        then
            console "[ INTERFACE ] LINK $RPIENV_BASH to $(dirname $ife) at the end"
        else
            console "[ INTERFACE ] INVALID CONFIG: $ife MISSING: SCRIPT and/or PROP"
            VALIDATION=$((VALIDATION + 1))
        fi
    done
}

function __init_and_create_base_env() {
    local new_env=""
    local var_name=""
    local var_path=""

    # clean up previous state
    echo "" > "$ENV_CACHE_PATH"
    echo "" > "$ALIAS_CACHE_PATH"
    # create base env vars
    for eenv in "${BASE_ENV_LIST[@]}"
    do
        new_env="export $eenv='${!eenv}'"
        console "[ CREATE ENV ] $new_env"
        addenv "$new_env"
    done

    # SET STORAGE PATHES
    if [ -e "$REPOROOT/cache/storage_path_structure" ]
    then
        while IFS= read -r line || [[ -n "$line" ]]
        do
            if [[ "$line" == *"="* ]]
            then
                var_name="$(echo "$line" | cut -d' ' -f2 | cut -d'=' -f1)"
                var_path="$(echo "$line" | cut -d' ' -f2 | cut -d'=' -f2)"
                new_env="export $var_name='$var_path'"
                console "[ CREATE ENV ] $new_env"
                addenv "$new_env"
            fi
        done < "$REPOROOT/cache/storage_path_structure"
    fi

    # SET DEVICE
    detect_device
    new_env="export DEVICE='$DEVICE'"
    console "[ CREATE ENV ] $new_env"
    addenv "$new_env"

    # SET OS
    var_path="$(uname -o 2>> /dev/null)"
    if [ "$?" -ne 0 ]
    then
        var_path="$(uname -s)"
    fi
    new_env="export OS='$var_path'"
    console "[ CREATE ENV ] $new_env"
    addenv "$new_env"
}

# CREATE ENV FILE BASED IN .RPIENV
function __create_env() {
    local name="$1"
    local path="$2"
    if [[ "${ENV_PROP_LIST[*]}" == *"$name"* ]]
    then
        name=$(echo "$name" | tr '[:lower:]' '[:upper:]')         # from bash 4.0: ${name^^}
        local new_env="export $name='$path'"
        console "[ CREATE ENV ] $new_env"
        addenv "$new_env"
    else
        console "[ ! CREATE ENV ] $name not in ${ENV_PROP_LIST[*]}"
    fi
}

# CREATE ALIASES FILE BASED IN .RPIENV
function __create_aliases() {
    local name="$1"
    local path="$2"
    if [[ "${ALIAS_PROP_LIST[*]}" == *"$name"* ]]
    then
        local new_ali="alias $name='$path'"
        console "[ CREATE ALIAS ] $new_ali"
        addalias "$new_ali"
    else
        console "[ ! CREATE ALIAS ] $name not in ${ALIAS_PROP_LIST[*]}"
    fi
}

# GENERATE PROP ARRAYS: ENV_PROP_LIST, ALIAS_PROP_LIST
function __add_to_prop_lists() {
    local input_list=($@)
    local name="${input_list[0]}"
    local prop=(${input_list[@]:1})
    for p in "${prop[@]}"
    do
        if [ "$p" == "env" ]
        then
            ENV_PROP_LIST+=("$name")
        elif [ "$p" == "alias" ]
        then
            ALIAS_PROP_LIST+=("$name")
        else
            console "Unknown env option: $p\navaliable: env | alias"
        fi
    done
    console "ENV_PROP_LIST=(${ENV_PROP_LIST[*]})"
    console "ALIAS_PROP_LIST=(${ALIAS_PROP_LIST[*]})"
    console "OTHER_PROP_LOST=(${OTHER_PROP_LOST[*]})"
}

# SOURCE THE GENERATED ENVIRONMENT
function source_env() {
    if [ "$VERBOSE" -eq 1 ]
    then
        console "ENV FILE VALID AND READY: $ENV_CACHE_PATH"
        cat "$ENV_CACHE_PATH"
    fi
    source "$ENV_CACHE_PATH"
}

# Create .rpienv source symlink next to the *.rpienv files
function create_dot_rpienv_source_links() {
    local dirname=""
    local rpienv_bash_full_path="${REPOROOT}/${RPIENV_BASH}"
    if [ "${#RPIENV_INTERFACES[@]}" -eq 0 ]
    then
        RPIENV_INTERFACES=($(find "$REPOROOT" -type f -name "$INTERFACE_INDICATOR"))
    fi

    for rpienv in "${RPIENV_INTERFACES[@]}"
    do
        dirname="$(dirname "$rpienv")"
        console "Create .rpienv source symlinks\n\tln -sf $rpienv_bash_full_path ${dirname}/.rpienv"
        $(ln -sf "$rpienv_bash_full_path" "${dirname}/.rpienv")
        if [ "$?" -eq 0 ]
        then
            console "\tSUCCESS"
        else
            console "\tFAILED"
        fi
    done
}

# CHECK THE ENV. GENERATION STATE
function env_result() {

    if [ "$ENV_CACHE_PATH_INITIALIZED" -eq 1 ] && [ "$VALIDATION" -ne 0 ]
    then
        if [ -f "$ENV_CACHE_PATH" ]
        then
            VALIDATION=$((VALIDATION-1))
        fi
    fi

    if [ "$VALIDATION" -eq 0 ]
    then
        # PRINTOUT FOR RESULT CHECK
        echo "OK[$VALIDATION]"
    else
        # PRINTOUT FOR RESULT CHECK
        echo "ERR[$VALIDATION]"
        VALIDATION=$((VALIDATION+1))
    fi
}

# GENERATE DEVICE ENV VAR
function detect_device() {
    local _DEVICE="OTHER"
    local model_path="/proc/device-tree/model"
    if [ -e "$model_path" ]
    then
        model="$(cat "$model_path" | tr '\0' '\n')"
        model="${model,,}"
        if [[ "$model" == *"raspberry"* ]]
        then
            _DEVICE="RASPBERRY"
        else
            _DEVICE="LINUX"
        fi
    else
        _UNAME="$(uname)"
	if [ "$_UNAME" == "Darwin" ]
        then
            _DEVICE="MACOS"
	elif [ "$_UNAME" == "Linux" ]
        then
            _DEVICE="LINUX"
	fi
    fi
    DEVICE=$_DEVICE
}

# MAIN BLOCK
function dynamic_env() {
    validate
    if [ "$VALIDATION" -ne 0 ] || [ "$FORCE" -eq 1 ]
    then
        create
        create_dot_rpienv_source_links
        source_env
        if [ "$DEVICE" != "MACOS" ]
        then
            cm_output=$("${CACHE_MANAGER}" "backup")
            console "$cm_output"
        fi
    fi
    source_env
    env_result
}

# EXECUTION
__elapsed_time "start"
dynamic_env
__elapsed_time "stop"

