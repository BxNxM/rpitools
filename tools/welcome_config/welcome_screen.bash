#!/bin/bash

# call my bootup services
boot_up_msg="true"
if [ "$boot_up_msg" == "true" ]
then
    wColor=""
    NC='\033[0m'
    if [ -e ~/welcomeColor.dat ]
    then
        source ~/welcomeColor.dat
        wColor=${SELECTED_COLOR}
    fi

    ip=$(hostname -I)
    echo -e "WELCOME ${wColor}${USER}${NC}! PI IP ADDRESS ${wColor}${ip}${NC}\nConnected from: ${wColor}$(~/rpitools/tools/get_connected_user_address.bash)${NC}"
    echo -e "WELCOME ${wColor}${USER}${NC}! PI IP ADDRESS ${wColor}${ip}${NC}"
    echo -e "TODAY: ${wColor}$(date)${NC}"
    echo -e "$(cal)"
    echo -e "${wColor}HOME DISK:${NC} $(du -sh ./ --exclude=./sshfs_folder)"
    echo -e ""
    echo -e "${wColor}AVAIBLE SERVICES AND TOOLS:${NC}"
    echo -e "Service (rpitools) interfaces:"
    echo -e "\toledinterface -h"
    echo -e "\trgbinterface -h"
    echo -e "\thapticengingeinterface -h"
    echo -e "\tomxplayer_gui -h"
    echo -e "Manage GUI (X):"
    echo -e "\tstartxbg\t-\tstart gui in the background"
    echo -e "\tpkill x \t-\tstop gui"
    echo -e "\tstartvnc\t-\tstart vnc service"
    echo -e ""
    echo -e "for more info use: ->| ${wColor}alias${NC} |<- command"
    echo -e "${wColor}########################################################${NC}"
fi
