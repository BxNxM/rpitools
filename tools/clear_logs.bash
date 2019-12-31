#!/bin/bash

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

#################################################################
#               LOG AND TMP FILE TYPES IN THE REPO              #
#################################################################

LOGS_PATH_LIST=($(find "${REPOROOT}" -iname "*.log"))
NOHUP_PATH_LIST=($(find "${REPOROOT}" -iname "nohup*"))
PYC_PATH_LIST=($(find "${REPOROOT}" -iname "*.pyc"))

#################################################################
#             LOG AND TMP FILE TYPES EXCEPTION LIST             #
#################################################################

EXCEPTION_LOGS_NOHUP_PYC=("sysmonitor_last.log")

#################################################################
#                            FUNCTIONS                          #
#################################################################

function rotate() {
    local save_list_x_lines=500
    local file_path="$1"
    local tmp_file_path="${file_path}_tmp.rot"
    local actual_line_number="$(cat $file_path | wc -l)"
    local execute=true

    for exc in ${EXCEPTION_LOGS_NOHUP_PYC[@]}
    do
        if [[ "$file_path" == *"$exc"* ]]
        then
            execute=false
        fi
    done

    if [[ "$actual_line_number" -gt "$save_list_x_lines" ]] && [[ "$execute" == "true" ]]
    then
        echo -e "\tRotate $file_path [delete: ${YELLOW}$((actual_line_number-save_list_x_lines))${NC} lines | save ${GREEN}$save_list_x_lines${NC} lines]"
        tail -n "$save_list_x_lines" "$file_path" > "$tmp_file_path"
        cat "$tmp_file_path" > "$file_path"
        rm -f "$tmp_file_path"
    else
        local exception=" [blacklisted: ${GREEN}true${NC}]"
        if [ "$execute" == "true" ]
        then
            exception=""
        fi
        echo -e "\tRotate $file_path - ${YELLOW}SKIP${NC}${exception}"
    fi
}

function remove() {
    local file_path="$1"
    local execute=true

    for exc in ${EXCEPTION_LOGS_NOHUP_PYC[@]}
    do
        if [[ "$file_path" == *"$exc"* ]]
        then
            execute=false
        fi
    done

    if [[ "$execute" == "true" ]]
    then
        echo -e "\tRemove $file_path"
        rm -f "$file_path"
    else
        echo -e "\tRemove $file_path - ${YELLOW}SKIP${NC}"
    fi
}

#################################################################
#                              MAIN                             #
#################################################################

echo -e "${PURPLE}ROTATE ALL LOG FILES IN THE REPO${NC}"
for file_path in "${LOGS_PATH_LIST[@]}"
do
    rotate "$file_path"
done
if [ "${#LOGS_PATH_LIST[@]}" == 0 ]
then
    echo -e "\tNone"
fi

echo -e "${PURPLE}ROTATE ALL NOHUP FILES${NC}"
for file_path in "${NOHUP_PATH_LIST[@]}"
do
    rotate "$file_path"
done
if [ "${#NOHUP_PATH_LIST[@]}" == 0 ]
then
    echo -e "\tNone"
fi

echo -e "${PURPLE}CLEAN ALL PYC FILES${NC}"
for file_path in "${PYC_PATH_LIST[@]}"
do
    remove "$file_path"
done
if [ "${#PYC_PATH_LIST[@]}" == 0 ]
then
    echo -e "\tNone"
fi
