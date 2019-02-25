#/bin/bash

ARG_LIST=($@)
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${MYDIR}/../prepare/colors.bash"

function _msg_() {
    local msg="$*"
    local title=" ${BLUE}[CLUSTER]${NC} "
    echo -e "$title$msg"
}

function get_commands() {
    local path_list=("${MYDIR}/interfaces")
    local command_full_path=""
    local commands_in_path=""
    commands_path_list=()

    for path in ${path_list[@]}
    do
        commands_in_path="$(ls -1 $path)"
        for command in ${commands_in_path[@]}
        do
            command_full_path="${path}/$command"
            if [ -f "$command_full_path" ]
            then
                commands_path_list+=("$command_full_path")
            fi
        done
    done

    _msg_ " ======================================="
    _msg_ "        Available Cluster commands"
    _msg_ " ======================================="
    _msg_ " ID\tCOMMAND"
    for ((k=0; k<${#commands_path_list[@]}; k++))
    do
        cmd="${commands_path_list[$k]}"
        _msg_ " $k\t$(basename $cmd)"
    done
    _msg_ " =======================================\n"
}

function list_and_execute() {
    get_commands
    new_commands_path_list=()
    ignore_asking=0
    # get command line arguments
    if [ "${#ARG_LIST[@]}" -gt 0  ]
    then
        _msg_ " Filter commands with command line argument: ${ARG_LIST[*]}"
        if [[ "${commands_path_list[*]}" == *"${ARG_LIST[*]}"* ]]
        then
            for ((k=0; k<${#commands_path_list[@]}; k++))
            do
                cmd="${commands_path_list[$k]}"
                if [[ "$cmd" == *"${ARG_LIST[*]}"* ]]
                then
                    new_commands_path_list+=("$cmd")
                fi
            done
        fi
        if [ "${#new_commands_path_list[@]}" -gt 0 ]
        then
            _msg_ " Find ${#new_commands_path_list[@]} command(s)"
            commands_path_list=${new_commands_path_list[@]}
            if [ "${#new_commands_path_list[@]}" -eq 1 ]
            then
                ignore_asking=1
            fi
        fi
    fi

    # read stdin argument
    for ((k=0; k<${#commands_path_list[@]}; k++))
    do
        cmd="${commands_path_list[$k]}"
        if [ "$ignore_asking" -ne 1 ]
        then
            read -p " What can I execute to you? [ID] " request
        else
            request=0
        fi
        _msg_ " Execute: $cmd\n"
        exec "$cmd"
    done
}

# main
list_and_execute
