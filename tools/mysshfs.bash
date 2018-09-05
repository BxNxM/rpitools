#!/bin/bash

# get arg list pcs
args_pcs=$#
# get arg list
arg_list=($@)

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# WRITE USER HERE
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

user="$($confighandler -s SSHFS -o user)"
default_host="$($confighandler -s SSHFS -o default_host)"
default_port="$($confighandler -s SSHFS -o default_port)"
external_port="$($confighandler -s SSHFS -o external_port)"
mount_folder_path="$($confighandler -s SSHFS -o mount_folder_path)"
default_halpage_name="official"

#-----------------------------------------------#
server_path="/home/${user}"                      # remote server path
sshfs_louncher_path="${MYDIR}/mysshfs.bash"      # actual script full path

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

# ------------------- SET ARG PARSER ----------------#
function init() {
    #__________________________!!!!!!!!!___________________________#
    ########################## SET THESE ###########################
    known_args=("man" "debug" "mount" "unmount" "ip" "port" "user" "mount_point")                             # valid arg list - add new args - call with -- expl: --man
    known_args_subs_pcs=(0 0 0 0 1 1 1 1)                                               # values for args - expl: --man -> 0, --example -> 1 etc.
    man_for_args=("--man\t\t::\tmanual"\                                        # add help text here
                  "--mount\t::\tmount server,  ${known_args_subs_pcs[2]} par"\
                  "--unmount\t::\tunmount server, ${known_args_subs_pcs[3]} par"\
                  "--ip\t::\tserver ip (optional), ${known_args_subs_pcs[4]} par"\
                  "--port\t::\tserver port (optional), ${known_args_subs_pcs[5]} par"\
                  "--user\t::\tserver username (optional), ${known_args_subs_pcs[6]} par"\
                  "--mount_point\t::\tlocal mount point for the server (optional), ${known_args_subs_pcs[7]} par")
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

# functions
function debug_param_info() {

    echo -e "user: $user"                               # from config | input par.
    echo -e "host: $host"                               # default_host | halpage_host | input par.
    echo -e "port: $port"                               # default_port | external_port | input par.
    echo -e "mount_folder_path: $mount_folder_path"     # from config | input par. | generated
    echo -e "default_halpage_name: $default_halpage_name" # from config | input par.
    echo -e "server_path: $server_path"                 # generated
}

function test_ip(){
    ip=$1
    p=$2
    echo -e "${YELLOW}Testing ip: ${ip}${NC}"
    ping -p ${p} ${ip} -c 2
    status=$?
    if [ $status == 0 ]
    then
        status=true
    else
        status=false
    fi
}

function get_info_from_dropbox_halpage() {
    local server_halpage_name="official"
    if [ "$server_halpage_name" != "None" ] | [ "$server_halpage_name" != "none" ]
    then
        echo -e "[INFO] Get host and port for the $server_halpage_name server from halpage (dropbox)"
        local halpage_handler="/home/$USER/rpitools/tools/dropbox_halpage/lib/server_info_getter.bash"
        host="$($halpage_handler --name $server_halpage_name --ip)"
        port="$($halpage_handler --name $server_halpage_name --port)"
        test_ip "$host" "$port"
        local status_="$status"
        echo -e "HOST:$host PORT:$port status:$status_"
    else
        echo -e "get_info_from_dropbox_halpage -> server_halpage_name: Not set in config [$server_halpage_name]"
    fi
}

function default_settings_mount() {
    test_ip "$default_host" "$default_port"
    if [ "$status" == "true" ]
    then
        echo -e "MOUNT WITH: $default_host $default_port"
        host="$default_host"
        port="$default_port"
        # TODO: mount with default settings
    fi
}

function dynamic_settings_mount() {
    test_ip "$host" "$port"
    if [ "$status" == "true" ]
    then
        echo -e "MOUNT WITH: $host $port"
        # TODO: mount with dynamic settings
    fi
}

#:::::::::::::::::::: MAIN USAGE ::::::::::::::::::::::
function main() {

    if [ "$args_pcs" -eq 1 ]
    then
        get_info_from_dropbox_halpage
    fi

    # run argparser
    argParseRun
    # check arg was called
    if [ "$(get_arg_status "ip")" -eq 1 ]
    then
        # get required arg values
        echo -e "IP: $(get_arg_value "ip")"
        host="$(get_arg_value "ip")"
    fi
    # check arg was called
    if [ "$(get_arg_status "port")" -eq 1 ]
    then
        # get required arg values
        echo -e "PORT: $(get_arg_value "port")"
        port="$(get_arg_value "port")"
    fi
    # check arg was called
    if [ "$(get_arg_status "user")" -eq 1 ]
    then
        # get required arg values
        user="$(get_arg_value "user")"
    else
        user="$($confighandler -s SSHFS -o user)"
    fi
    # check arg was called
    if [ "$(get_arg_status "mount_point")" -eq 1 ]
    then
        # get required arg values
        echo -e "MOUNT POINT: $(get_arg_value "mount_point")"
        mount_point="$(get_arg_value "mount_point")"
    fi
    # check arg was called
    if [ "$(get_arg_status "mount")" -eq 1 ]
    then
        # get required arg values
        echo -e "mount was called with parameters: ->|$(get_arg_value "mount")|<-"
        default_settings_mount
        if [ "$status" != "true" ]
        then
            dynamic_settings_mount
        fi
    fi
    # check arg was called
    if [ "$(get_arg_status "unmount")" -eq 1 ]
    then
        # get required arg values
        echo -e "unmount was called with parameters: ->|$(get_arg_value "unmont")|<-"
    fi
}

main
debug_param_info
