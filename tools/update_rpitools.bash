#!/bin/bash

arg_len="$#"
option="$1"
if [ "$arg_len" -eq 1 ]
then
    if [ "$option" != "start" ] && [ "$option" != "stop" ]
    then
        option="stop"
        echo -e "[ WARNING ] - wrong given option $option -> start/stop"
    fi
else
    echo -e "[ WARNING ] - option is not given -> start/stop"
fi

function config_is_changed_on_HEAD() {
    local is_changed="$(git fetch && git diff origin/master ~/rpitools/autodeployment/config/rpitools_config_template.cfg)"
    if [ "$is_changed" != "" ]
    then
        echo -e "====== [ WARNING ] ======"
        echo -e "rpitools_config_template.cfg changed - MANUAL SETTINGS NEEDED!"
        echo -en "ARE YOU SURE TO CONTINUE? Y | N >"
        read  areyousure
        if [ "$areyousure" == "n" ] || [ "$areyousure" == "N" ]
        then
            echo -e "Update stopping... OK"
            exit 3
        else
            echo -e "Update continue... OK"
        fi
    else
        echo -e "HEAD rpitools_config_template.cfg not changed - manual interrupt not needed."
    fi
}

function stop_running_processes() {
    process_list=("oled_gui_core" "dropbox_halpage" "auto_restart_transmission" "rpitools_logrotate" "rgb_led_controller" "memDictCore")
    for process in "${process_list[@]}"
    do
        is_exists=$(ls -1 /lib/systemd/system | grep -v grep | grep "$process")
        is_run=$(ps aux | grep "$process" | grep -v grep)
        if [ "$is_run" != "" ] && [ "$is_exists" != "" ]
        then
            echo -e "sudo systemctl stop $process"
            sudo systemctl stop "$process"
        fi
    done
}

function start_running_processes() {
    process_list=("memDictCore" "oled_gui_core" "dropbox_halpage" "auto_restart_transmission" "rpitools_logrotate" "rgb_led_controller")
    for process in "${process_list[@]}"
    do
        is_exists=$(ls -1 /lib/systemd/system | grep -v grep | grep "$process")
        is_run=$(ps aux | grep "$process" | grep -v grep)
        if [ "$is_run" == "" ] && [ "$is_exists" != "" ]
        then
            echo -e "sudo systemctl start $process"
            sudo systemctl start "$process"
        fi
    done
}

config_is_changed_on_HEAD
if [ "$option" == "stop" ]
then
    echo -e "STOP PROCESSES"
    stop_running_processes
    echo -e "UPDATE"
elif [ "$option" == "start" ]
then
    echo -e "START PROCESSES"
    start_running_processes
    echo -e "DONE"
fi
exit 0
