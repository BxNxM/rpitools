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

function stop_running_services() {
    service_list=("oled_gui_core" "dropbox_halpage" "auto_restart_transmission" "rpitools_logrotate" "rgb_led_controller" "memDictCore")
    for service in "${service_list[@]}"
    do
        is_exists=$(ls -1 /lib/systemd/system | grep -v grep | grep "$service")
        is_run=$(ps aux | grep "$service" | grep -v grep)
        if [ "$is_run" != "" ] && [ "$is_exists" != "" ]
        then
            echo -e "sudo systemctl stop $service"
            sudo systemctl stop "$service"
        fi
    done
}

function start_running_services() {
    service_list=("memDictCore" "oled_gui_core" "dropbox_halpage" "auto_restart_transmission" "rpitools_logrotate" "rgb_led_controller")
    for service in "${service_list[@]}"
    do
        is_exists=$(ls -1 /lib/systemd/system | grep -v grep | grep "$service")
        is_run=$(ps aux | grep "$service" | grep -v grep)
        if [ "$is_run" == "" ] && [ "$is_exists" != "" ]
        then
            if [ "$(systemctl is-enabled $service)" == "enabled" ]
            then
                echo -e "sudo systemctl start $service"
                sudo systemctl start "$service"
            else
                echo -e "systemctl is-enabled $service => disabled - autostart after upgrade off"
            fi
        fi
    done
}

config_is_changed_on_HEAD
if [ "$option" == "stop" ]
then
    echo -e "STOP SERVICES"
    stop_running_services
    echo -e "UPDATE"
elif [ "$option" == "start" ]
then
    /home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py -v
    exit_code="$?"
    if [ "$exit_code" -ne 0 ]
    then
        echo -e "Set your configuration berfore continue!\n${GREEN}confhelper, and press D${NC}"
        echo -e "CAN NOT START SERVICES!"
    else
        echo -e "Your configuration is valid :D"
        echo -e "START SERVICES "
        start_running_services
        echo -e "DONE"
    fi
fi
exit 0
