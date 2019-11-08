#!/bin/bash

######################################################
#               ARG FUNCTION FRAMEWORK               #
######################################################

ARGS_LIST=($@)
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AV_FUNCTIONS=""
FUNCTIONS_BLACKLIST=("validate_execute_function" "check_exitcode" "message" "create_docker_persistent_storage_dir")
PATCH_EXIT_CODE=0
# EXITCODES:
#       INPUT ERROR: 1
#       EXEC ERROR: 2

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
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BLUE}[ RPI DOCKER ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BLUE}[ RPI DOCKER ]${NC} $msg" >> "$rpitools_log_path"
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

function create_docker_persistent_storage_dir() {
    DOCKER_STORAGE_DIR="$OTHERSPACE/docker_storage"             # should we expose?
    DOCKER_META_DIR="$DOCKER_STORAGE_DIR/meta"                  # should we expose?
    if [ ! -d "$DOCKER_STORAGE_DIR" ]
    then
        sudo bash -c 'mkdir -p '"$DOCKER_STORAGE_DIR"' && chgrp docker '"$DOCKER_STORAGE_DIR"''
    fi
    if [ ! -d "$DOCKER_META_DIR" ]
    then
        sudo bash -c 'mkdir -p '"$DOCKER_META_DIR"' $$ chgrp docker '"$DOCKER_META_DIR"''
    fi
}
create_docker_persistent_storage_dir

#########################################
#               FUNCTIONS               #
#########################################
function build() {
    # URL: https://docs.docker.com/engine/reference/commandline/build/
    local docker_file_path="$1"
    local name="$2"
    local label="rpitools"
    local image_meta_path="$DOCKER_META_DIR/images/"
    local image_id_file="$image_meta_path/${label}_${name}.dat"
    local commandstr="docker build . --file $docker_file_path --label $label --tag ${label}:${name} --iidfile $image_id_file"

    if [ ! -f "$docker_file_path" ]
    then
        message "Docker file as first parameter not exists: docker_file_path: $docker_file_path"
        exit 1
    fi
    if [ "$name" == "" ]
    then
        message "Docker image name mandatory as second parameter."
        exit 1
    fi

    if [ ! -d "$image_meta_path" ]
    then
        sudo bash -c "mkdir -p $image_meta_path && chgrp -R docker $image_meta_path && chmod ugo+rw $image_meta_path"
    fi

    message "Docker build:\n\t$commandstr"
    sudo bash -c "eval $commandstr"
}

function export_image() {
    local image_name="$1"
    local image_archive_path="$DOCKER_STORAGE_DIR/image_archive"
    local commandstr="docker export $image_name > ${image_archive_path}/${image_name}.tar"

    if [ ! -d "$image_archive_path" ]
    then
        sudo bash -c "mkdir -p $image_archive_path && chgrp -R docker $image_meta_path && chmod ugo+rw $image_meta_path"
    fi

    message "Export docker image:\n\t$commandstr"
    sudo bash -c "eval $commandstr"
}

function load_image() {
    local image_archive_path="$DOCKER_STORAGE_DIR/image_archive"

    message "Load image from $image_archive_path "
}

function run() {
    local args="$*"
    #TODO: add default volume and save container id

    message "Docker run: $args"
    eval $args
}

function info() {
    echo -e "Docker containers host dir: $DOCKER_STORAGE_DIR"
    echo -e "Docker containers meta dir: $DOCKER_META_DIR"
    echo -e "Dokcer containers image archive: $DOCKER_STORAGE_DIR/image_archive"
}

#########################################
#               EXECUTION               #
#########################################
validate_execute_function "${ARGS_LIST[0]}"
eval "${ARGS_LIST[*]}"
exit "$PATCH_EXIT_CODE"
