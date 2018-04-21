#!/bin/bash

argslen="$#"
arg="$1"

if [ "$argslen" -eq 1 ]
then
    if [ "$arg" -eq 0 ] || [ "$arg" -eq 1 ]
    then
        echo -e "QUICK SSHFS OPTION ACTIVATED [0-mount] [1-unmount]"
        option="$arg"
    else
        echo -e "Unknown option: ${option}\n\t0 - mount\n\t1 - unmount"
        exit 1
    fi
fi

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#------------------------------------------ CONFIG ----------------------------------------------------#
# WRITE USER HERE
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

user="$($confighandler -s SSHFS -o user)"
default_host="$($confighandler -s SSHFS -o default_host)"
default_port="$($confighandler -s SSHFS -o default_port)"
external_port="$($confighandler -s SSHFS -o external_port)"
mount_folder_path="$($confighandler -s SSHFS -o mount_folder_path)"

#-----------------------------------------------#
serverPATH="/home/${user}"                      # remote server path
localPATH="$mount_folder_path"                  # pi server path
ip_file_path=${MYDIR}/.ext_server_ip.dat        # store extarnal ip address
sshfs_louncher_path=${MYDIR}/sshfs.bash         # actual script full path

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

#------------------------------------------ FUNCTIONS ----------------------------------------------------#
function Simple_fileReader {            #FILE READER, READ FROM PATH TO ARRAY: search_line
    local filepath=$ip_file_path
    if [ -e "$filepath" ]
    then
        search_line=()

        while read line || [ -n "$line" ]
        do
            search_line+=($line)
        done < "$filepath"
    else
        search_line=""
    fi
}

function logo() {
    echo -e "${RED}
       _____    _____   _    _   ______    _____
      / ____|  / ____| | |  | | |  ____|  / ____|
     | (___   | (___   | |__| | | |__    | (___
     '\___ \   \___ \  |  __  | |  __|    \___ \'
      ____) |  ____) | | |  | | | |       ____) |
     |_____/  |_____/  |_|  |_| |_|      |_____/
     ${NC}"
    echo -e "_______________MOUNT YOUR SERVER________________"
}

# settings specific - default ip and port (internal, external)
function guess_connection_port() {
    local actual_ip=$1
    if [ "$actual_ip" == "$default_host" ]
    then
        # IT IS AN INTERNAL ADDRESS
        port=${default_port}
    else
        # IT IS AN EXTERNAL ADDRESS
        port=${external_port}
    fi
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

function get_ip_from_user(){
    local filepath=$ip_file_path
    echo -e "${LIGHT_GREEN}"
    echo -n "Write server new ip address [ENTER]:"
    read new_ip
    echo -e "${NC}"
    echo ${new_ip} > $filepath
    restart_script
}

function restart_script(){
    echo -e "If program not relounch automaticly, close and open again app again..."
    for ((i=0; i<2; i++))
    do
        echo -e "${i}/2 sec"
        sleep 1
    done
    echo -e "Restart $sshfs_louncher_path"
    sleep 1
    clear
    exec "$sshfs_louncher_path" && exit 0
}

function get_host_and_port() {
    Simple_fileReader
    host="${search_line[0]}"
    if [ -z $host ]
    then
	# WRITE DEFAULT IP HERE
    	host=${default_host}
        guess_connection_port $host
        test_ip $host $port
        echo -e $status
        if [ "$status" == "false" ]
        then
            get_ip_from_user
        fi
    else
        guess_connection_port $host
        test_ip $host $port
        echo -e "Host ${host} is avaible? ${status}"
        if [ "$status" == "false" ]
        then
            get_ip_from_user
        fi
    fi
}

function create_config_file(){
    echo -e "Add host to config: ${ip_file_path}"
    get_ip_from_user
}
#-------------------------------------------- MAIN ----------------------------------------------------#
logo
if [ -z "$option" ]
then
    echo -e "${RED}WRITE OPTION:\n(Press 0) MOUNT TO: $serverPATH -> $localPATH\n(Press 1) UNMOUNT FROM:$localPATH${NC}"
    echo -e "${RED}(PRESS 2) CREATE CONFOG FILE ${ip_file_path} ${NC}"
    echo -n ">"
    read option
fi

if [ "$option" -eq 0 ]
then
    echo -e "${RED}\tMOUNT: => $serverPATH -> $localPATH${NC}"
    if [ ! -d $localPATH ]
    then
    	mkdir $localPATH
    fi

    if [ -d $localPATH ]
    then
        # get valid host and port | from file and stdin
        get_host_and_port
    	echo "MOUNT: => cmd: sshfs -p $port -o follow_symlinks $user@$host:$serverPATH $localPATH"
        sshfs -p $port -o follow_symlinks $user@$host:$serverPATH $localPATH
        exit 0
    else
    	echo -e "$localPATH NOT EXIST YET"
    fi

elif [ "$option" -eq 1 ]
then
    echo -e "${RED}\tUNMOUNT: => $localPATH${NC}"
    sudo umount $localPATH
    exit 0

elif [ "$option" -eq 2 ]
then
    create_config_file
    exit 0

else
    echo -e "${RED}\tINVALID PARAMETER${NC}"
    exit 1
fi
