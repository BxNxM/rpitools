#!/bin/bash

arglist=($@)

commands_whitelist=("diskhandler" "halpage" "hapticinterface" "kodibg" "listlocalrpis" "motioncontroll" "mysshfs" "oledinterface" "rgbinterface" "sysmonitor" "ttyecho" "smartpatch")
commands_blacklist=("ll")

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGAHNDLER="${MYDIR_}/../../autodeployment/bin/ConfigHandlerInterface.py"
source ${MYDIR_}/../colors.bash
aliases_path="${MYDIR_}/../../template/aliases"
commands_name_list=($(cat "$aliases_path"  | grep "='.*.'" | cut -d' ' -f2 | cut -d"=" -f1))
commands_name_counter=0
commands_list=$(cat "$aliases_path" | grep "='.*.'" | cut -d"'" -f2)
user_commands_folder="/usr/bin/"
cache_indicator_path="${MYDIR_}/../../cache/.system_wide_commands_was_set"

_msg_title="SYSTEM CMD CREATE"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_RED}[ $_msg_title ]${NC} - $msg"
}

function create_commands() {
    while read -r cmd
    do
        command_name="${commands_name_list[$commands_name_counter]}"
        if [ "$command_name" != "" ] && [[ "${commands_whitelist[*]}" == *"$command_name"*  ]] && [[ "${commands_blacklist[*]}" != *"$command_name"* ]]
        then
            command_path="${user_commands_folder}${command_name}"
            _msg_ "$command_name -> $command_path"

            _command="#!/bin/bash\n"
            _command+="HOME_bak="'\"\$HOME\"'"\n"
            _command+="USER_bak="'\"\$USER\"'"\n"
            _command+="HOME="'\"'"$HOME"'\"'"\n"
            _command+="USER="'\"'"$USER"'\"'"\n"
            _command+="REPOROOT="'\"$REPOROOT\"'"\n"
            sudo bash -c "echo -e \"$_command\" > \"$command_path\""
            sudo bash -c "echo '$cmd \$*' >> \"$command_path\""
            _command="HOME="'\"\$HOME_bak\"'"\n"
            _command+="USER="'\"\$USER_bak\"'"\n"
            sudo bash -c "echo -e \"\n$_command\" >> \"$command_path\""

            sudo bash -c "sudo chmod ugo+x $command_path"
        fi
        commands_name_counter=$((commands_name_counter+1))
    done <<< "$commands_list"

    echo -e "$(date)" > "$cache_indicator_path"
}

function list_cmds() {
    local existing_commands_list=($(ls -1 "$user_commands_folder"))
    for cmd in "${commands_whitelist[@]}"
    do
        if [[ "${existing_commands_list[*]}" == *"$cmd"* ]]
        then
            _msg_ "Command: $cmd OK"
        else
            _msg_ "Command: $cmd MISSING - run: ${MYPATH_} create"
        fi
    done
}

if [ "${#arglist[@]}" -eq 1 ] && [ "${arglist[0]}" == "create" ]
then
    _msg_ "Create system wide commands"
    create_commands
elif [ "${#arglist[@]}" -eq 1 ] && [ "${arglist[0]}" == "list" ]
then
    _msg_ "List system wide commands"
    list_cmds
fi

if [ "${#arglist[@]}" -eq 0 ]
then
    if [ ! -e "$cache_indicator_path" ]
    then
        _msg_ "System wide commands auto setup..."
        create_commands
    else
        _msg_ "System wide commands was already set: $cache_indicator_path exists."
        _msg_ "Manual args: ${MYPATH_} create | list"
    fi
fi
