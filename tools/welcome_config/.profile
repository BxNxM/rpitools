# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

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
    echo -e "${wColor}########################################################${NC}"
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
