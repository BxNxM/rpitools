#!/bin/bash

#set -x

# get arg list pcs
args_pcs=$#
# get arg list
arg_list=($@)

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# WRITE USER HERE
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
# HALPAGE HANDLER
halpage_handler="/home/$USER/rpitools/tools/dropbox_halpage/lib/server_info_getter.bash"

user="$($confighandler -s SSHFS -o user)"
default_host="$($confighandler -s SSHFS -o default_host)"
default_port="$($confighandler -s SSHFS -o default_port)"
external_port="$($confighandler -s SSHFS -o external_port)"
mount_folder_path="$($confighandler -s SSHFS -o mount_folder_path)"
default_halpage_name="$($confighandler -s SSHFS -o halpage_name)"
halpage_is_available="$($confighandler -s EXTIPHANDLER -o activate)"

#-----------------------------------------------#
server_path="/home/${user}"                      # remote server path
sshfs_louncher_path="${MYDIR}/mysshfs.bash"      # actual script full path
MODE="None"

#--------------------------------------------- COLORS ----------------------------------------------------#
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

function info_msg() {
    echo -e "${YELLOW}[INFO][MODE:$MODE]${NC} ${*}"
}

# ------------------- SET ARG PARSER ----------------#
function init() {
    #__________________________!!!!!!!!!___________________________#
    ########################## SET THESE ###########################
    known_args=("man" "debug" "mount" "unmount" "ip" "port" "user" "mount_point" "halpage_name" "list_halpage" "m" "u" "remount" "sshkey_sync")
    known_args_subs_pcs=(0 0 0 0 1 1 1 1 1 0 0 0 0 0)
    man_for_args=("--man\t\t::\tmanual"\
                  "--mount [m]\t::\tmount server,  ${known_args_subs_pcs[2]} par"\
                  "--unmount [u]\t::\tunmount server, ${known_args_subs_pcs[3]} par"\
                  "--ip\t\t::\tserver ip (optional) grp0, ${known_args_subs_pcs[4]} par"\
                  "--port\t\t::\tserver port (optional) grp0, ${known_args_subs_pcs[5]} par"\
                  "--user\t\t::\tserver username (optional) grp0, ${known_args_subs_pcs[6]} par"\
                  "--mount_point\t::\tlocal mount point for the server (optional) grp1, ${known_args_subs_pcs[7]} par"\
                  "--halpage_name\t::\thalpage identifier name (optional) grp0, ${known_args_subs_pcs[8]} par"\
                  "--list_halpage\t::\tlist halpage server names grp2, ${known_args_subs_pcs[9]} par"\
                  "--remount\t::\tunmount and mount server, ${known_args_subs_pcs[10]} par"\
                  "--sshkey_sync\t::\tsync ssh key to remote server for the passwordless connection, ${known_args_subs_pcs[11]} par")
    #______________________________________________________________#
    ################################################################
    known_args_status=()
    known_args_value=()
    error_happened=0

    for init_value in "${known_args[@]}"
    do
        # set value to one
        known_args_status+=("0")
        known_args_value+=("")
    done
}

#--- VALIDATE LISTS SYNCRON & ERRORS & ARG VALUES ---#
function validate() {

    if [[ "${known_args_value[*]}" == *"--"* ]] || [ "$error_happened" -eq 1 ]
    then
        echo -e "[!!!] args error, use --man for more info."
        exit 400
    fi

    if [ "${#known_args[@]}" -ne "${#known_args_subs_pcs[@]}" ]
    then
        echo -e "[!!!] config error, known_args len and known_args_subs_pcs len is not equel!"
        exit 401
    fi

    validcommandwasfind=0
    for iscalled in "${known_args_status[@]}"
    do
        validcommandwasfind=$((validcommandwasfind+iscalled))
    done
    if [ "$validcommandwasfind" -eq 0 ] && [ "$args_pcs" -gt 0 ]
    then
        echo -e "[!!!] valid arg not find, use --man for more info."
        exit 402
    fi
}

# ----------------- ARG PARSER CORE ----------------#
function arg_parse() {
    error_happened=0
    for((i=0;i<"${#arg_list[@]}";i++))
    do
        for((k=0;k<"${#known_args[@]}";k++))
        do
            buffer=""
            case "${arg_list[$i]}" in
                "--${known_args[$k]}")
                    # set value to one
                    known_args_status[$k]="1"
                    args_max=$((i + ${known_args_subs_pcs[$k]} + 1))
                    #echo -e "arg max: $args_max"
                    if [ ${#arg_list[@]} -eq $args_max ] || [ ${#arg_list[@]} -gt $args_max ]
                    then
                        for((args_val="$((i+1))"; args_val<="$i"+"${known_args_subs_pcs[$k]}"; args_val++))
                        do
                            buffer+="${arg_list["$args_val"]} "
                        done
                        known_args_value[$k]="$buffer"
                    else
                       echo -e "${arg_list[$i]} arg required ${known_args_subs_pcs[$k]} parameter, $((${known_args_subs_pcs[$k]}+args_pcs-args_max)) were given"
                        error_happened=1
                        known_args_status[$k]="0"
                    fi
                    # debug message
                    #Message="ARGS METCHED: ${arg_list[$i]} <=> ${known_args[$k]}"
                    ;;
            esac
        done
    done
}
# ------------------- GET STATUS FOR ARG -------------#
function get_arg_status() {
    key="$1"
    for((index=0;index<"${#known_args[@]}";index++))
    do
        if [ "$key" == "${known_args["$index"]}" ]
        then
            echo "${known_args_status["$index"]}"
        fi
    done
}
# ---------------- GET VALUE(S) FOR ARG ---------------#
function get_arg_value() {
    local key="$1"
    local bare_output=""
    for((index=0;index<"${#known_args[@]}";index++))
    do
        if [ "$key" == "${known_args["$index"]}" ]
        then
            bare_output=$(echo "${known_args_value["$index"]}" | sed 's/^ *//g' | sed 's/ *$//g')       # HANDLE TRAILING WHITESPACES
            echo "${bare_output}"
        fi
    done
}
# ---------------------- MAN PAGE --------------------#
function man() {
    if [ "$(get_arg_status "man")" -eq 1 ]
    then
        for manpage in "${man_for_args[@]}"
        do
            echo -e "$manpage"
        done
    fi
}
function debug_print() {
    echo -e "KNOWN ARGS: ${known_args[*]}\t\t\t:::   known arguments"
    echo -e "KNOWN ARGS SUB ELEMENTS PIECES: ${known_args_subs_pcs[*]}\t\t\t:::   known args reguired parameters pieces"
    echo -e "KNOWN ARGS STATUS: ${known_args_status[*]}\t\t\t\t:::   args status, is colled?"
    echo -e "ARGS ARGS VALUE(S): ${known_args_value[*]}\t\t\t\t:::   args reguired read parameters"
}
# ------------------- MAIN FUNCTION -------------------#
function argParseRun() {
    init
    arg_parse
    validate
    if [ "$(get_arg_status "debug")" -eq 1 ]
    then
        debug_print
    fi
    man
}

function logo() {
    echo -e "${RED}
          _____    _____   _    _   ______    _____
         / ____|  / ____| | |  | | |  ____|  / ____|
        | (___   | (___   | |__| | | |__    | (___
        '\___ \   \___ \  |  __  | |  __|    \___ \'
         ____) |  ____) | | |  | | | |       ____) |
     my |_____/  |_____/  |_|  |_| |_|      |_____/
     ${NC}"
    echo -e "_______________MOUNT YOUR SERVER________________"
    if [ "$args_pcs" -eq 0 ]
    then
        info_msg "For more info: mysshfs --man"
    fi
}

# functions
function debug_param_info() {

    info_msg "CONNECTION DETAILS:"
    info_msg "user: $user"                               # from config | input par.
    info_msg "host: $host"                               # default_host | halpage_host | input par.
    info_msg "port: $port"                               # default_port | external_port | input par.
    info_msg "mount_folder_path: $mount_folder_path"     # from config | input par. | generated
    info_msg "default_halpage_name: $default_halpage_name" # from config | input par.
    info_msg "server_path: $server_path"                 # generated
}

function validate_host(){
    local ip=$1
    local p=$2
    info_msg "Testing host: ${ip} :: $p"
    ping -p ${p} ${ip} -c 2
    status="$?"
    if [ $status == 0 ]
    then
        echo -e "\t$(info_msg "${GREEN}Succesfully located${NC}")"
        status=true
    else
        echo -e "\t$(info_msg "Can't found")"
        status=false
    fi
}

function get_info_from_dropbox_halpage() {
    local server_halpage_name="$1"

    if [ "$halpage_is_available" == "True" ] || [ "$halpage_is_available" == "true" ]
    then
        if [ "$server_halpage_name" != "None" ] | [ "$server_halpage_name" != "none" ]
        then
            info_msg "Get host and port for the $server_halpage_name server from halpage (dropbox)"
            host="$($halpage_handler --name $server_halpage_name --ip)"
            port="$($halpage_handler --name $server_halpage_name --port)"
            validate_host "$host" "$port"
            local status_="$status"
            echo -e "HOST:$host PORT:$port status:$status_"
        else
            echo -e "get_info_from_dropbox_halpage -> server_halpage_name: Not set in config [$server_halpage_name]"
        fi
    else
        info_msg "Halpage api was not activated (see in rpitools_config.cfg) Use this app directly: --ip --port --user"
    fi
}

function default_settings_mount() {
    MODE="DEFAULT"
    info_msg "Attempt to connect with config settings..."
    validate_host "$default_host" "$default_port"
    if [ "$status" == "true" ]
    then
        echo -e "MOUNT WITH: $default_host $default_port"
        host="$default_host"
        port="$default_port"
        # TODO: mount with default settings
    fi
}

function dynamic_settings_mount() {
    MODE="DEFAULT HALPAGE"
    info_msg "Appempt to connect with halpage settings..."
    get_info_from_dropbox_halpage "$default_halpage_name"
    validate_host "$host" "$port"
    if [ "$status" == "true" ]
    then
        echo -e "MOUNT WITH: $host $port"
        # TODO: mount with dynamic settings
    fi
}

function connect_with_manual_settings() {
    MODE="MANUAL"
    info_msg "Attept to connect with manual settings..."
    if [ ! -z "$halpage_name" ]
    then
        MODE="MANUAL HALPAGE"
        info_msg "Attempt to connect with manual settings with halpage api (dropbox) to $halpage_name server"
        get_info_from_dropbox_halpage "$halpage_name"
    else
        if [ "$manual_connection" -gt 2 ]
        then
            MODE="MANUAL PARAMETERS"
            info_msg "Attept to connect with manual settings ip, port, host"
        else
            MODE="INVALID"
            info_msg "INVALID PARAMETER SET, REQUIRED: --ip, --port, --user"
        fi
    fi

}

function mount_sshfs() {
    debug_param_info
    if [ ! -d "$mount_folder_path" ]
    then
        info_msg "Create mount point: $mount_folder_pat"
        sudo mkdir -p "$mount_folder_path"
        sudo chown -R "$USER" "$mount_folder_path"
        sudo chgrp -R "$USER" "$mount_folder_path"
    else
        info_msg "Mount point exists: $mount_folder_pat"
    fi

    echo "MOUNT: => cmd: sshfs -p $port -o follow_symlinks $user@$host:$server_path $mount_folder_path"
    sshfs -p $port -o follow_symlinks $user@$host:$server_path $mount_folder_path
    local exitcode="$?"
    if [ "$exitcode" -eq 0 ]
    then
        echo -e "\t$(info_msg "${GREEN}SUCCESS${NC} [$exitcode]")"
        info_msg "Server $host contenet $mount_folder_path:"
        ls -lth "$mount_folder_path"
    else
        echo -e "\t$(info_msg "${RED}FAIL${NC} [$exitcode]")"
    fi
}

function unmount_sshfs() {
    if [ -e  "$mount_folder_path" ]
    then
        info_msg "UNMOUNT: => $mount_folder_path"
        sudo umount "$mount_folder_path"
        local exitcode="$?"
        if [ "$exitcode" -eq 0 ]
        then
            echo -e "\t$(info_msg "${GREEN}SUCCESS${NC} [$exitcode]")"
            rmdir "${mount_folder_path}"
        else
            echo -e "\t$(info_msg "${RED}FAIL${NC} [$exitcode]")"
        fi
    else
        info_msg "$mount_folder_path NOT FOUND"
    fi
}

function remount_sshfs() {
    info_msg "REMOUNT SSHFS SERVER"
    echo -e "$($MYPATH --unmount)"
    echo -e "$($MYPATH --mount)"
}

#:::::::::::::::::::: MAIN USAGE ::::::::::::::::::::::
function main() {
    logo
    local manual_connection=0

    # run argparser
    argParseRun

    # check arg was called
    if [ "$(get_arg_status "sshkey_sync")" -eq 1 ]
    then
        if [ "$manual_connection" -eq 0 ]
        then
            default_settings_mount
            if [ "$status" != "true" ]
            then
                dynamic_settings_mount
            fi
        else
            connect_with_manual_settings
        fi
        info_msg "Copy ssh ~/.ssh/id_rsa.pub -> ${user}@${host}:~/.ssh/authorized_keys"
        . "${MYDIR}/copy_my_sshkey_to.bash" "${user}@${host}"
    fi
    # check arg was called
    if [ "$(get_arg_status "list_halpage")" -eq 1 ]
    then
        if [ "$halpage_is_available" == "True" ] || [ "$halpage_is_available" == "true" ]
        then
            echo -e "$($halpage_handler --list )"
        else
            info_msg "Halpage api was not activated (see in rpitools_config.cfg) SORRY This option is not available!"
        fi
    fi
    # check arg was called
    if [ "$(get_arg_status "ip")" -eq 1 ]
    then
        # get required arg values
        manual_connection=$((manual_connection+1))
        echo -e "IP: $(get_arg_value "ip")"
        host="$(get_arg_value "ip")"
    fi
    # check arg was called
    if [ "$(get_arg_status "port")" -eq 1 ]
    then
        # get required arg values
        manual_connection=$((manual_connection+1))
        echo -e "PORT: $(get_arg_value "port")"
        port="$(get_arg_value "port")"
    fi
    # check arg was called
    if [ "$(get_arg_status "user")" -eq 1 ]
    then
        # get required arg values
        manual_connection=$((manual_connection+1))
        user="$(get_arg_value "user")"
        server_path="/home/$user"
    fi
    # check arg was called
    if [ "$(get_arg_status "mount_point")" -eq 1 ]
    then
        # get required arg values
        echo -e "MOUNT POINT: $(get_arg_value "mount_point")"
        mount_folder_path="$(get_arg_value "mount_point")"
        manual_connection=$((manual_connection+1))
    elif [ "$user" != "$($confighandler -s SSHFS -o user)" ]
    then
        mount_folder_path="/media/$user"
    fi
    # check arg was called
    if [ "$(get_arg_status "halpage_name")" -eq 1 ]
    then
        # get required arg values
        echo -e "HALPAGE NAME: $(get_arg_value "halpage_name")"
        halpage_name="$(get_arg_value "halpage_name")"
        manual_connection=$((manual_connection+1))
    fi

    # check arg was called
    if [ "$(get_arg_status "mount")" -eq 1 ] || [ "$(get_arg_status "m")" -eq 1 ]
    then
        if [ "$manual_connection" -eq 0 ]
        then
            default_settings_mount
            if [ "$status" != "true" ]
            then
                dynamic_settings_mount
            fi
        else
            connect_with_manual_settings
        fi
        mount_sshfs
    fi
    # check arg was called
    if [ "$(get_arg_status "unmount")" -eq 1 ] || [ "$(get_arg_status "u")" -eq 1 ]
    then
        # get required arg values
        unmount_sshfs
    fi
    # check arg was called
    if [ "$(get_arg_status "remount")" -eq 1 ]
    then
        remount_sshfs
    fi
}

main
