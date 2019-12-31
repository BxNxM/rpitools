#!/bin/bash

arg_len="$#"
arg_list=($@)
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

source "$TERMINALCOLORS"

#################################
#           INPUT DATA          #
#################################
# PATH LISTS
BACKUP_PATH="${HOME}/.rpitools_bckp/"
REQ_BACKUP_SUB_PATH_LIST=("/cache/" \
                          "/gpio/Adafruit_Python_SSD1306/" \
                          "/autodeployment/config/" \
                          "/tools/dropbox_halpage/lib/Dropbox-Uploader/" \
                          "/autodeployment/lib/retropie/RetroPie-Setup/" \
                          "/tools/gotop/gotop" \
                          "/tools/socketmem/lib/.dictbackup.json"
                          "/autodeployment/lib/apache_setup/h5ai-0.29.0.zip" \
                          "/autodeployment/lib/apache_setup/_h5ai")
__COMPONENT_CONFIGS_PATH_LIST=($(find "${REPOROOT}/autodeployment/" -type d -name 'config'))
for comp_path in ${__COMPONENT_CONFIGS_PATH_LIST[@]}
do
    COMPONENT_CONFIGS_PATH_LIST+=("${comp_path//$REPOROOT}")
done
# FINALIZE PATH LIST
REQ_BACKUP_SUB_PATH_LIST+=(${COMPONENT_CONFIGS_PATH_LIST[@]})

FILE_NAME_BLACKLIST=("confeditor.bash")
#################################

# message handler function
function message() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "${PURPLE}[ CACHE ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ CACHE ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

function backup_restre_file_progress_indicator() {
    local rpitools_log_path="${REPOROOT}/cache/rpitools.log"
    local msg="$*"

    echo -en "\e[1A";
    echo -e "\e[0K\r ${msg}"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${PURPLE}[ CACHE ]${NC} $msg" >> "$rpitools_log_path"
}

function cleanUP_cache() {
    local patch_blacklist=()
    for black in ${FILE_NAME_BLACKLIST[@]}
    do
        patch_blacklist=($(find "${BACKUP_PATH}" -type f -name "$black"))
        for path in ${patch_blacklist[@]}
        do
            if [ -e "$path" ]
            then
                message "Remove based on blacklist [$black]: $path"
                rm -f "$path"
            fi
        done
    done
}

function __backup() {
    message "=== ${PURPLE}BACKUP CACHE${NC} ==="
    message "\tshow cached contnet with: cache_manager show\n"
    local PATH_ROOT="$REPOROOT"
    local from_path=""
    local to_path=""
    for sub_path in ${REQ_BACKUP_SUB_PATH_LIST[@]}
    do
        from_path="${PATH_ROOT}${sub_path}"
        if [ -d "${PATH_ROOT}${sub_path}" ]
        then
            to_path="${BACKUP_PATH}$(dirname ${sub_path})"
            basename_of_to_path="$to_path"
        else
            to_path="${BACKUP_PATH}${sub_path}"
            basename_of_to_path="$(dirname $to_path)"
        fi
        if [ -e "$from_path" ]
        then
            backup_restre_file_progress_indicator "\t${PURPLE}EXPORT${NC} CACHE: $from_path -> $to_path"
            if [ ! -d "$basename_of_to_path"  ]
            then
                message "\t - Create $basename_of_to_path basedir"
                mkdir -p "$basename_of_to_path"
            fi
            sudo bash -c "cp -raf $from_path $to_path"
            if [ "$?" -ne 0 ]
            then
                message "\t\t$[${RED}ERR${NC}]"
            fi
        else
            message "\tFROM PATH: $from_path NOT EXISTS... ${PURPLE}SKIPPING${NC}"
        fi
    done
    cleanUP_cache
}

function __restore() {
    message "=== ${PURPLE}RESTORE CACHE${NC} ==="
    message "\tshow cached contnet with: cache_manager show\n"
    cleanUP_cache
    local PATH_ROOT="$BACKUP_PATH"
    local from_path=""
    local to_path=""
    for sub_path in ${REQ_BACKUP_SUB_PATH_LIST[@]}
    do
        from_path="${PATH_ROOT}${sub_path}"
        if [ -d "${PATH_ROOT}${sub_path}" ]
        then
            to_path="${REPOROOT}$(dirname ${sub_path})"
        else
            to_path="${REPOROOT}${sub_path}"
        fi
        if [ -e "$from_path" ]
        then
            basename_of_to_path="$(dirname $to_path)"
            backup_restre_file_progress_indicator "\t${PURPLE}RESTORE${NC} CACHE: $from_path -> $to_path"
            if [ ! -d "$basename_of_to_path"  ]
            then
                message "\t - Create $basename_of_to_path basedir"
                mkdir -p "$basename_of_to_path"
            fi
            sudo bash -c "cp -raf $from_path $to_path"
            if [ "$?" -ne 0 ]
            then
                message "\t\t$[${RED}ERR${NC}]"
            fi
        else
            message "\tFROM PATH: $from_path NOT EXISTS... ${PURPLE}SKIPPING${NC}"
        fi
    done
}

function __show() {
    tree "$BACKUP_PATH" -L 3
}

if [ "$arg_len" == 1 ]
then
    if [ "${arg_list[0]}" == "backup" ]
    then
        __backup
    elif [ "${arg_list[0]}" == "restore" ]
    then
        __restore
    elif [ "${arg_list[0]}" == "show" ]
    then
        __show
    else
        message "Invalid input ${arg_list[0]}\n\tTry backup/restore/show"
    fi
else
    message "AVAIBLE INPUTS: backup/restore/show\nthese are cache saving options for easier repo status maintenance."
fi
