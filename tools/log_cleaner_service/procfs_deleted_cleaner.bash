#!/bin/bash

NC='\033[0m'
YELLOW='\033[1;33m'

function lsof_deleted() {
    echo -e "\n${YELLOW}============================"
    echo -e "lost of deleted procfs file:"
    echo -e "============================${NC}"
    sudo lsof | grep deleted
}

function disk_state() {
    echo -e "\n${YELLOW}============================="
    echo -e "sudo df -h /"
    echo -e "=============================${NC}"
    sudo df -h /

    echo -e "\n${YELLOW}============================="
    echo -e "sudo du -csh /*"
    echo -e "=============================${NC}"
    sudo du -csh /*

}

function choose_boss_is_needed() {
    echo -e "${YELLOW}sudo logrotate -f /etc/logrotate.conf"
    echo -e "Is cleenup needed? [Y/N]${NC}"
    read option
    if [ "$option" == "Y" ]
    then
        echo -e "${YELLOW}Cleanup: sudo logrotate -f /etc/logrotate.conf${NC}"
        sudo logrotate -f /etc/logrotate.conf
    else
        echo -e "${YELLOW}Skipping ... Goodbye${NC}"
    fi
}

lsof_deleted
disk_state
choose_boss_is_needed
