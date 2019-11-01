#!/bin/bash

arglist=($@)

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

source ${TERMINALCOLORS}

user_commands_folder="/usr/bin/"
cache_indicator_path="${REPOROOT}/cache/.system_wide_commands_was_set"

_msg_title="SYSTEM CMD CREATE"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${LIGHT_RED}[ $_msg_title ]${NC} - $msg"
}

function create_commands() {
    while read cmd
    do
        command_name="$(echo $cmd | cut -d'=' -f1 | tr -d '\n')"
        if [ "$command_name" != "" ]
        then
            command_executable="$(echo $cmd | cut -d'=' -f2 | tr -d '\n')"
            command_path="${user_commands_folder}${command_name}"
            _msg_ "$command_name -> $command_path [$command_executable]"

            _command="#!/bin/bash\n"
            _command+="bash -c \"source '$ENV_CACHE_PATH' && $command_executable \$* 2>/dev/null\""
            sudo bash -c "echo -e '$_command' > \"$command_path\""
            sudo bash -c "sudo chmod ugo+x $command_path"
            if [ "$?" -eq 0 ]
            then
                _msg_ "\t[ ${GREEN}OK${NC} ] $command_name"
            else
                _msg_ "\t[ ${RED}ERR${NC} ] $command_name"
            fi
        fi
    done < "$CMD_CACHE_PATH"

    echo -e "$(date)" > "$cache_indicator_path"
}

function list_cmds() {
    _msg_ "RpiTools commands: $user_commands_folder"
    while read cmd
    do
        command_name="$(echo $cmd | cut -d'=' -f1 | tr -d '\n')"
        if [ "$command_name" != "" ]
        then
            all_deployed_commands="$(ls -1 $user_commands_folder)"
            if [[ "$all_deployed_commands" == *"$command_name"* ]]
            then
                _msg_ "[ ${GREEN}OK${NC} ] $command_name"
            else
                _msg_ "[ ${YELLOW}MISSING${NC} ] $command_name"
            fi
        fi
    done < "$CMD_CACHE_PATH"
}

if [ "${#arglist[@]}" -eq 1 ] && [ "${arglist[0]}" == "create" ]
then
    _msg_ "Create system wide commands based on $CMD_CACHE_PATH under $user_commands_folder"
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
        _msg_ "Manual args: ${MYPATH} create | list"
    fi
fi
