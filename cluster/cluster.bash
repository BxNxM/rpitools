#/bin/bash

ARG_LIST=($@)
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

    echo -e " ======================================="
    echo -e "        Available Cluster commands"
    echo -e " ======================================="
    echo -e " ID\tCOMMAND"
    for ((k=0; k<${#commands_path_list[@]}; k++))
    do
        cmd="${commands_path_list[$k]}"
        echo -e " $k\t$(basename $cmd)"
    done
    echo -e " =======================================\n"
}

function list_and_execute() {
    get_commands
    for ((k=0; k<${#commands_path_list[@]}; k++))
    do
        cmd="${commands_path_list[$k]}"
        read -p " What can I execute to you? [ID] " request
        echo -e " Execute: $cmd\n"
        exec "$cmd"
    done
}

# main
list_and_execute
