#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../prepare/colors.bash"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
transmission_downloads_path="$($confighandler -s TRANSMISSION -o download_path)"

storage_path_structure="${MYDIR_}/../cache/storage_path_structure"
if [ -f "$storage_path_structure" ]
then
    source "$storage_path_structure"
    # get USERSPACE variable
fi

#########################################################################################
#                                 ARGUMENTUM HANDLER                                    #
#########################################################################################
# get arg list pcs
args_pcs=$#
# get arg list
arg_list=($@)

# script path n name
MY_PATH="`dirname \"$0\"`"
MY_NAME="`basename \"$0\"`"

# ------------------- SET ARG PARSER ----------------#
function init() {
    #__________________________!!!!!!!!!___________________________#
    ########################## SET THESE ###########################
    known_args=("man" "debug" "adduser" "removeuser" "changepasswd" "userstat" "logoff")                             # valid arg list - add new args - call with -- expl: --man
    known_args_subs_pcs=(0 0 2 1 2 0 0)                                               # values for args - expl: --man -> 0, --example -> 1 etc.
    man_for_args=("--man\t\t::\tmanual"\                                        # add help text here
                  "--adduser\t::\tAdd new user with settings, <username> <userpasswd> ${known_args_subs_pcs[2]} par"\
                  "--removeuser\t::\tRemove user, <username> ${known_args_subs_pcs[3]} par"\
                  "--changepasswd\t::\tChange user password, <username> <userpasswd> ${known_args_subs_pcs[4]} par"\
                  "--userstat\t::\tShow users list and used disk space ${known_args_subs_pcs[5]} par"\
                  "--logoff\t::\tLog off user - select after execute ${known_args_subs_pcs[6]} par")
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
#:::::::::::::::::::: MAIN USAGE ::::::::::::::::::::::
function ARGPARSE() {
    # run argparser
    argParseRun
    # check arg was called
    if [ "$(get_arg_status "adduser")" -eq 1 ]
    then
        # get required arg values
        echo -e "adduser was called with parameters: ->|$(get_arg_value "adduser")|<-"
        adduser_arglist=($(get_arg_value "adduser"))
        create_custom_user "${adduser_arglist[0]}" "${adduser_arglist[1]}"
    fi
    # check arg was called
    if [ "$(get_arg_status "removeuser")" -eq 1 ]
    then
        # get required arg values
        echo -e "removeuser was called with parameters: ->|$(get_arg_value "removeuser")|<-"
        remove_user "$(get_arg_value 'removeuser')"
    fi
    # check arg was called
    if [ "$(get_arg_status "changepasswd")" -eq 1 ]
    then
        # get required arg values
        echo -e "changepasswd was called with parameters: ->|$(get_arg_value "changepasswd")|<-"
        changepwd_arglist=($(get_arg_value "changepasswd"))
        set_user_password "${changepwd_arglist[0]}" "${changepwd_arglist[1]}"
    fi

    if [ "$(get_arg_status "userstat")" -eq 1 ]
    then
        show_users_stat
    fi

    # check arg was called
    if [ "$(get_arg_status "logoff")" -eq 1 ]
    then
        LogOffUser
    fi

    if [ "$args_pcs" -eq 0 ]
    then
        bash "$MYPATH_" --man
    fi
}

#########################################################################################
#                                       APPLICATION                                     #
#########################################################################################
_msg_title="RPITOOLS USER MANAGER"
function _msg_() {
    local msg="$1"
    echo -e "${LIGHT_RED}[ $_msg_title ]${NC} - $msg"
}

function create_user_storage() {
    username="$1"
    if [ ! -z "${USERSPACE}" ]
    then
        _msg_ "Create storage on disk for user ${username} -> ${USERSPACE}/${username}"
        sudo bash -c "mkdir -p ${USERSPACE}/${username}"
        sudo chown "${username}" "${USERSPACE}/${username}"
        sudo chgrp "${username}" "${USERSPACE}/${username}"
        _msg_ "Linking storage from disk ${USERSPACE}/${username} -> /home/${username}/storage"
        sudo bash -c "ln -sf ${USERSPACE}/${username} /home/${username}/storage"
    fi
}

function create_custom_user() {
    local username="$1"
    local userpasswd="$2"

    if [ -d /home/${username} ]
    then
        _msg_ "USER ${username} ALREADY EXISTS."
    else
        _msg_ "ADD CUSTOM USER: sudo useradd -c \"created by rpitools\" -m \"${username}\""
        sudo useradd -c "created by rpitools" -m "${username}"

        set_user_password "$username" "$userpasswd"

        _msg_ "SET DEFAULT SHELL TO BASH FOR USER $username"
        sudo chsh -s /bin/bash "$username"

        _msg_ "Add new user to group: rpitools_user"
        sudo bash -c "sudo usermod -a -G rpitools_user $username"

        __copy_user_temaplete "$username"

        create_user_storage "$username"
    fi
}

function set_user_password() {
    local username="$1"
    local userpasswd="$2"

    _msg_ "SET PASSWORD: echo \"${username}:*******\" | sudo chpasswd"
    echo "${username}:${userpasswd}" | sudo chpasswd

    cleanup_history
}

function remove_user() {
    local username="$1"

    _msg_ "REMOVE USER WITH HOME DIR: sudo deluser --remove-home $username"
    sudo deluser --remove-home "$username"

    if [ -e "${USERSPACE}/${username}" ]
    then
        _msg_ "Remove ${USERSPACE}/${username}"
        sudo bash -c "rm -rf ${USERSPACE}/${username}"
    fi
}

function show_users_stat() {
    local users=($(ls -1 /home))
    echo -e "USER\tDISK\tPATH"
    for user in "${users[@]}"
    do
        echo -e "${user}\t$(sudo du -sh /home/${user})"
    done
}

function __copy_user_temaplete() {
    local username="$1"
    local temaplet_dir="/home/$USER/rpitools/template/user_home_template/"
    local template_content=($(ls -1 "$temaplet_dir"))
    local sharedmovies_path="/home/${username}/SharedMovies"
    for file in "${template_content[@]}"
    do
        if [[ "$file" == *".dat"* ]]
        then
            _msg_ "COPY $temaplet_dir$file -> /home/${username}/$file"
            sudo cp "$temaplet_dir$file" "/home/${username}/$file"
        else
            _msg_ "COPY $temaplet_dir$file -> /home/${username}/.$file"
            sudo cp "$temaplet_dir$file" "/home/${username}/.$file"
        fi
    done

    _msg_ "SET USER PERMISSION FOR THE COPIED FILES"
    sudo chown -R "${username}" "/home/${username}/"
    sudo chgrp -R "${username}" "/home/${username}/"

    if [ ! -e "$sharedmovies_path" ]
    then
        _msg_ "Linking $transmission_downloads_path -> $sharedmovies_path"
        sudo ln -s "$transmission_downloads_path" "$sharedmovies_path"

        _msg_ "Add $username to the debian-transmission group."
        sudo usermod -a -G debian-transmission "$username"
    fi
}

function LogOffUser {
	ps aux | egrep "sshd: [a-zA-Z]+@"
	echo -e "${LIGHT_RED}Kill User [PID]:${NC}"
	read PID
	sudo kill -9 $PID
	echo -e "${LIGHT_RED}$PID KILLED!${NC}"
}

function cleanup_history() {
    _msg_ "Cleaning up history for security reasons:"
    _msg_ "#############################################"
    _msg_ 'cat /dev/null > ~/.bash_history && history -c'
    _msg_ "#############################################"
}

ARGPARSE
