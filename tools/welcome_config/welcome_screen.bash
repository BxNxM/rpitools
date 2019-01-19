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
    echo -e "${wColor}HOME DISK:${NC} $(du -sh $HOME --exclude=$HOME/sshfs_folder)"
if [ "$boot_up_msg" == "true" ]
then
    echo -e ""
    echo -e "${wColor}AVAILABLE SERVICES AND TOOLS:${NC}"
    echo -e "${wColor}-----------------------------${NC}"
    echo -e "${wColor}Service (rpitools) interfaces:${NC}"
    echo -e "\toledinterface -h\t-> oled service command line control"
    echo -e "\trgbinterface -h\t\t-> rgb command line control"
    echo -e "\thapticinterface -h\t-> vibre motor cmd line control"
    echo -e "\tsysmonitor -h\t\t-> system monitoring tool"
    echo -e "\tdiskhandler -h\t\t-> external disks handling based on fstab"
    echo -e "\tconfighandler -h\t-> config handler based on rpitools_config.cfg [programs API]"
    echo -e "\tconfeditor\t\t-> interactive config handler for easy modifications. [Human API]"
    echo -e "\tmysshfs --man\t\t-> built in sshfs based on rpitools_config.cfg or manual parameters"
    echo -e "\tupdate_rpitools\t\t-> update your repository with an easy command :D"
    echo -e "\tnetwork_monitor\t\t-> show actual network traffic"
    echo -e "\thalpage -h\t\t-> if you set extarnal (dropbox based) IP handling"
    echo -e "\tclientMemDict -h\t-> access for the internal ram memory dict structure [programs API]"
    echo -e "\tbackuphandler\t\t-> system / users home(s) backup / restore creator based on rpitools_config.cfg"
    echo -e "\trpihelp\t\t\t-> show this help screen again :D"

    echo -e "${wColor}Manage GUI (X):${NC}"
    echo -e "\tstartxbg\t\t-> start gui in the background"
    echo -e "\tpkill x \t\t-> stop gui"
    echo -e "\tstartvnc\t\t-> start vnc service"
    echo -e "\tkodibg\t\t\t-> start kodi media center"

    echo -e "${wColor}Camera (over built in camera connector):${NC}"
    echo -e "\tcamera --man\t\t-> get more info ablot camera interface"
    echo -e "\tmotioncontroll <par>\t-> controll connected motion camera: start | stop | status"

    echo -e "${wColor}User handling - create - delete:${NC}"
    echo -e "\tusermanager --man\t-> see the available options: create, delete, change password, list"
    echo -e "\tsudo visudo\t\t-> show sudoers file"

    echo -e "${wColor}Other commands:${NC}"
    echo -e "\tAdd new user for\n\t\
apache webshared dir:\thtpasswd -cb /home/$USER/.secure/apasswords user_name user_pwd"
    echo -e "\tAdd new samba user:\tsudo smbpasswd -a samba_user"
    echo -e "\tGlances system monitor: http://$(hostname).local:61208"
    echo -e "\tRetropie wrapper:\tretropie"
    echo -e ""
    echo -e "for more info use: ->| ${wColor}alias${NC} |<- command"
    echo -e "${wColor}########################################################${NC}"
fi
