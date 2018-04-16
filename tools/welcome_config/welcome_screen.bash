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
    echo -e "\toledinterface -h\t-> oled service command line control"
    echo -e "\trgbinterface -h\t\t-> rgb command line control"
    echo -e "\thapticinterface -h\t-> vibre motor cmd line control"
    echo -e "\tsysmonitor -h\t\t-> system monitoring tool"
    echo -e "\tdiskhandler -h\t\t-> external disks handling based on fstab"
    echo -e "\tconfighandler -h\t-> config handler based on rpitools_config.cfg"
    echo -e "\tmysshfs\t\t\t-> built in sshfs based on rpitools_config.cfg"
    echo -e "\tupdate_rpitools\t\t-> update your repository"
    echo -e "Manage GUI (X):"
    echo -e "\tstartxbg\t\t-> start gui in the background"
    echo -e "\tpkill x \t\t-> stop gui"
    echo -e "\tstartvnc\t\t-> start vnc service"
    echo -e "\tkodibg\t\t\t-> start kodi media center"
    echo -e "Other commands:"
    echo -e "\tAdd new user for\n\t\
apache webshared dir:\thtpasswd -cb /home/$USER/.secure/apasswords user_name user_pwd"
    echo -e "\tAdd new samba user:\tsudo smbpasswd -a samba_user"
    echo -e ""
    echo -e "for more info use: ->| ${wColor}alias${NC} |<- command"
    echo -e "${wColor}########################################################${NC}"
fi
