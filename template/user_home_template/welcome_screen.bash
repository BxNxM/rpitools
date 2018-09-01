#!/bin/bash

# call my bootup services
boot_up_msg="true"

wColor=""
NC='\033[0m'
if [ -e ~/welcomeColor.dat ]
then
    source ~/welcomeColor.dat
    if [[ ! -z "$WELCOME_TEXT_ENV" ]]
    then
        WELCOME_TEXT="true"
    fi
    if [[ ! -z "$WELCOME_TEXT" ]] && [[ "$WELCOME_TEXT" != "true" ]] && [[ "$WELCOME_TEXT" != "True" ]]
    then
        boot_up_msg="false"
    fi
    wColor=${SELECTED_COLOR}
fi

    ip=$(hostname -I)
    echo -e "${wColor} _     _  _______  ___      _______  _______  __   __  _______"
    echo -e "| | _ | ||       ||   |    |       ||       ||  |_|  ||       |"
    echo -e "| || || ||    ___||   |    |       ||   _   ||       ||    ___|"
    echo -e "|       ||   |___ |   |    |       ||  | |  ||       ||   |___"
    echo -e "|       ||    ___||   |___ |      _||  |_|  ||       ||    ___|"
    echo -e "|   _   ||   |___ |       ||     |_ |       || ||_|| ||   |___"
    echo -e "|__| |__||_______||_______||_______||_______||_|   |_||_______|${NC}"
    echo -e ""
    echo -e "${wColor}${USER}${NC}! LOCAL IP ADDRESS ${wColor}${ip}${NC}\nConnected from: ${wColor}$(~/rpitools/tools/get_connected_user_address.bash)${NC}"
    echo -e "TODAY: ${wColor}$(date)${NC}"
    echo -e "$(cal)"
    echo -e "${wColor}HOME DISK:${NC} $(du -sh ./ --exclude=./sshfs_folder)"
if [ "$boot_up_msg" == "true" ]
then
    echo -e ""
    echo -e "${wColor}AVAILABLE SERVICES AND TOOLS:${NC}"
    echo -e "${wColor}-----------------------------${NC}"
    echo -e "${wColor}Service (rpitools) interfaces:${NC}"
    echo -e "\tsysmonitor -h\t\t-> system monitoring tool"
    echo -e "\trpihelp\t\t\t-> show this help screen again :D"
fi
