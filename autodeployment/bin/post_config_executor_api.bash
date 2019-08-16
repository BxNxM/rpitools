#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKDIR="${MYDIR}/../lib"
ERR_CNT=0
RUN_MODULES_LIST=()
TEMPLATE_EXECUTION=false
DEP_NOT_EXECUTED_YET_LIST=()
DEPENDENCY_INSTALL_CNT=1
DEPENDENCY_INSTALL_MAX_RETRY=20

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

_msg_title="CONFIG POST ACTIONS"
function console() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${GREEN}[ $_msg_title ]${NC} - $msg"
}

function save_run_modules_load_order() {
    local runmodule="$1"
    local action="$2"
    local save_pathMYD="${MYDIR}/run_modules_order.dat"

    if [ "$action" == "init" ]
    then
        echo -e "[ $(date) ] - INIT" > "$save_pathMYD"
    fi

    if [ "$action" == "evaluate" ]
    then
        local lines="$(cat $save_pathMYD | wc -l)"
        echo -e "[ $(date) ] - EVAL $((lines-1))" >> "$save_pathMYD"
    fi

    if [ "$runmodule" != "-" ]
    then
        echo -e "[ $(date) ] - $runmodule" >> "$save_pathMYD"
    fi
}

function validate_env() {
    console "########################"
    console "#      validate_env    #"
    console "########################"
    if [ -d "$WORKDIR" ]
    then
        console "[ ENV ] OK"
    else
        console "[ ENV ] ERROR"
        ERR_CNT=$((ERR_CNT+1))
    fi
}

function validate_module_path() {
    local path="$1"
    local mandatory_types_list=(".run" "config")
    local content="$(ls -1 $path)"
    local type_cnt=0
    for type_ in ${mandatory_types_list[@]}
    do
        if [[ "$content" == *"$type_"* ]]
        then
            type_cnt=$((type_cnt+1))
        else
            console "\t$type_ not in $content"
        fi
    done

    if [ "${#mandatory_types_list[@]}" -ne "$type_cnt" ]
    then
        console "\t${RED}INVALID${NC}"
    fi
}

function DEP_ADD() {
    local dep_name="$1"
    local __run_link_name="$(basename $runmodule)"
    local RUN_LINK_NAME="${__run_link_name%.*}"
    DEP_NOT_EXECUTED_YET_LIST+=("$RUN_LINK_NAME")
}

function REMOVE_DEP() {
    local dep_name="$1"
    local __run_link_name="$(basename $runmodule)"
    local RUN_LINK_NAME="${__run_link_name%.*}"
    local DEP_NOT_EXECUTED_YET_LIST_BUFFER=()

    for check_name in "${DEP_NOT_EXECUTED_YET_LIST[@]}"
    do
        if [[ "$check_name" != "$RUN_LINK_NAME" ]]
        then
            DEP_NOT_EXECUTED_YET_LIST_BUFFER+=("$check_name")
        else
            save_run_modules_load_order "$check_name"
        fi
    done
    DEP_NOT_EXECUTED_YET_LIST=(${DEP_NOT_EXECUTED_YET_LIST_BUFFER[@]})
    if [ "${#DEP_NOT_EXECUTED_YET_LIST[@]}" -ne 0 ]
    then
        console "[${#DEP_NOT_EXECUTED_YET_LIST[@]}] ${DARK_GRAY}INSTALL LIST:${NC} ${DEP_NOT_EXECUTED_YET_LIST[*]}"
    fi
}

function parse_run_modules() {
    console "########################"
    console "#   parse_run_modules  #"
    console "########################"
    local run_modules_list=($(find "$WORKDIR" -name "*.run" -type f))
    for runmodule in ${run_modules_list[@]}
    do
        console "[ PARSE RUN MODULES ] ADD $runmodule"
        # exceptions handling
        if [[ "$runmodule" != *"__template_package_structure"* ]]
        then
            if [[ "${RUN_MODULES_LIST[*]}" != *"$runmodule"* ]]
            then
                # RUN MAIN MODUL PARSING
                RUN_MODULES_LIST+=("$runmodule")
                validate_module_path "$(dirname $runmodule)"
                DEP_ADD "$runmodule"
            else
                console "${RED}[WARNING]${NC} - redundant runUID: $runmodule"
            fi
        # DEBUG TEMPLATE ADD TO MAIN PARSING LIST
        elif [[ "$TEMPLATE_EXECUTION" == "true" ]] && [[ "$runmodule" == *"__template_package_structure"* ]]
        then
            if [[ "${RUN_MODULES_LIST[*]}" != *"$(basename $runmodule)"* ]]
            then
                RUN_MODULES_LIST+=("$runmodule")
                validate_module_path "$(dirname $runmodule)"
                DEP_ADD "$runmodule"
            else
                console "${RED}[WARNING]${NC} - redundant runUID: $runmodule"
                ERR_CNT=$((ERR_CNT+1))
            fi
        fi
    done
    console "[ PARSE RUN MODULES ] PARSED: ${#RUN_MODULES_LIST[@]}"
}

function execute_run_modules() {
    console "########################"
    console "#  execute_run_modules #"
    console "########################"
    local dep_cnt=0
    for runmodule in ${RUN_MODULES_LIST[@]}
    do
        TITLE="$(source $runmodule && echo $TITLE)"
        SCRIPT="$(source $runmodule && echo $SCRIPT)"
        RUN_DEPENDENCY=("$(source $runmodule && echo ${RUN_DEPENDENCY[*]})")
        SCRIPT_PATH="$(dirname $runmodule)"
        SCRIPT="${SCRIPT_PATH}/$SCRIPT"
        dep_cnt=0
        local __run_link_name
        local RUN_LINK_NAME
        for dep in ${RUN_DEPENDENCY[@]}
        do
            __run_link_name="$(basename $runmodule)"
            RUN_LINK_NAME="${__run_link_name%.*}"
            if [[ "${DEP_NOT_EXECUTED_YET_LIST[*]}" == *"${dep}"* ]] && [[ "${dep}" != "$RUN_LINK_NAME" ]]
            then
                dep_cnt=$((dep_cnt+1))
            fi
        done

        if [[ "$dep_cnt" -eq 0 ]] && [[ "${#DEP_NOT_EXECUTED_YET_LIST[@]}" -gt 0 ]]
        then
            __run_link_name="$(basename $runmodule)"
            RUN_LINK_NAME="${__run_link_name%.*}"
            if [[ ${DEP_NOT_EXECUTED_YET_LIST[*]} == *"$RUN_LINK_NAME"* ]]
            then
                console "${YELLOW}[ ROUND: $DEPENDENCY_INSTALL_CNT ] [ EXECUTE ]${NC} ${PURPLE}$TITLE${NC} - RUN UID: $RUN_LINK_NAME\n $SCRIPT"
                output=$("$SCRIPT")
                console "\n$output"
                REMOVE_DEP "$runmodule"
            #else
            #    console "${YELLOW}[ ROUND: $DEPENDENCY_INSTALL_CNT ] [ ALREADY DONE ]${NC} ${PURPLE}$TITLE${NC} - RUN UID: $RUN_LINK_NAME\n $SCRIPT"
            fi
        elif [[ "${#DEP_NOT_EXECUTED_YET_LIST[@]}" -gt 0 ]]
        then
            console "\t |_ ${YELLOW}[ ROUND: $DEPENDENCY_INSTALL_CNT ] SHIFT INSTALLING runUID:${NC} $RUN_LINK_NAME\n$SCRIPT"
            console "\t |__ DEP: ${RUN_DEPENDENCY[*]}"
        else
            console "DONE [${#DEP_NOT_EXECUTED_YET_LIST[@]}]: (${DEP_NOT_EXECUTED_YET_LIST[*]})"
            break
        fi
    done

    while [[ "${#DEP_NOT_EXECUTED_YET_LIST[@]}" -ne 0 ]]
    do
        DEPENDENCY_INSTALL_CNT=$((DEPENDENCY_INSTALL_CNT+1))
        if [ "$DEPENDENCY_INSTALL_CNT" -lt "$DEPENDENCY_INSTALL_MAX_RETRY" ] || [ "$DEPENDENCY_INSTALL_CNT" -eq "$DEPENDENCY_INSTALL_MAX_RETRY" ]
        then
            execute_run_modules
        else
            ERR_CNT=$((ERR_CNT+1))
            console "INSTALL EXECUTION RETRY TIMEOUT [$DEPENDENCY_INSTALL_MAX_RETRY] CONTENT: ${DEP_NOT_EXECUTED_YET_LIST[*]}"
        fi
    done
}

function post_config_actions_done() {
    local cache_dir="${REPOROOT}/cache/"
    local indicator_file="${cache_dir}/.post_config_actions_done"
    if [ ! -f "$indicator_file" ]
    then
        echo -e "$(date)" > "${indicator_file}"
    fi
}

# ||||||||||||||||| #
#       MAIN        #
# ||||||||||||||||| #
save_run_modules_load_order "-" "init"
validate_env
parse_run_modules
execute_run_modules
save_run_modules_load_order "-" "evaluate"

# ||||||||||||||||| #
#  RUN USER SCRIPT  #
# ||||||||||||||||| #
userscript_is_activated="$($CONFIGHANDLER -s USER_SPACE -o activate)"
if [ "$userscript_is_activated" == "true" ] || [ "$userscript_is_activated" == "True" ]
then
    console "USER SCRIPT WAS ACTIVATED"
    console "\t$($CONFIGHANDLER --user_script)"
    path="$($CONFIGHANDLER -s USER_SPACE -o path)"
    shellcheck "$path"
    if [ "$?" -ne 0 ]
    then
        console "\tShellcheck validation failed, please check your script with shellcheck\nand correct the error(s) and warning(s)."
    else
        console "RUN: bash $path"
        console "\n################################## $(date '+%Y.%m.%d %H:%M:%S') ##################################"
        sudo bash "$path"
        echo -e "################################## $(date '+%Y.%m.%d %H:%M:%S') ##################################"
    fi
else
    console "USER SCRIPT WAS NOT ACTIVATED"
fi

# ||||||||||||||||| #
#      EVALUATE     #
# ||||||||||||||||| #
if [ "$ERR_CNT"  -eq 0 ]
then
    console "POST INSTALLATION WAS ${GREEN}SUCCESSFULL${NC} :) [$ERR_CNT]"
else
    console "POST INSTALLATION WAS ${RED}FAILED${NC} :( [$ERR_CNT]"
fi
