#!/bin/bash

function stop_running_processes() {
    process_list=("oled_gui_core")
    for process in "${process_list[@]}"
    do
        is_run=$(ps aux | grep "$process" | grep -v grep)
        if [ "$is_run" != "" ]
        then
            echo -e "sudo systemctl stop $process"
            sudo systemctl stop "$process"
        fi
    done
}

function update_rpitools() {
    cd /home/$USER/

    echo -e "Delete obsolete rpitools"
    sudo rm -rf /home/$USER/rpitools

    echo -e "Clone new rpitools"
    git clone https://github.com/BxNxM/rpitools.git

    echo -e "Source up rpitools (restore previous cache and configurations)"
    cd rpitools/
    source setup
}

echo -e "STOP PROCESSES"
stop_running_processes
echo -e "UPDATE"
update_rpitools