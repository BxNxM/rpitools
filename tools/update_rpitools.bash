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
    process_list=("dropbox_halpage")
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

echo -e "STOP PROCESSES"
stop_running_processes
echo -e "UPDATE"
