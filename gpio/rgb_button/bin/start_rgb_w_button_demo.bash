#!/bin/bash

rgb_service_path="/home/pi/rpitools/gpio/rgb_led/bin/rgb_led_controller.py"
rgb_demo="/home/pi/rpitools/gpio/rgb_led/bin/rgb_demo.py"
button_event_handler_path="/home/pi/rpitools/gpio/rgb_button/lib/ButtonHandler.py"
button_event_path="/home/pi/rpitools/gpio/rgb_button/lib/button_event"
rgb_interface_path="/home/pi/rpitools/gpio/rgb_led/bin/rgb_interface.py"
rgb_button_cache_folder="./cache"

if [ ! -d "$rgb_button_cache_folder" ]
then
    mkdir "$rgb_button_cache_folder"
fi


function start_servive() {
    is_run_service=$(ps aux | grep [r]gb_led_controller.py)
    echo -e "$is_run_service"
    if [ "$is_run_service" == "" ]
    then
        pushd /home/pi/rpitools/gpio/rgb_led/bin/
        ./rgb_led_controller.py & > /dev/null
        pid=$(ps axf | grep rgb_led_controller.py | grep -v grep | awk '{print $1}')
        popd
        echo -e "$pid" > "${rgb_button_cache_folder}/rgb_led_controller_pid.dat"
    else
        echo -e "rgb_led_controller.py already running."
    fi
}

function start_demo() {
    is_run_demo=$(ps aux | grep [r]gb_demo.py)
    if [ "$is_run_demo" == "" ]
    then
        pushd /home/pi/rpitools/gpio/rgb_led/bin/
        ./rgb_demo.py & > /dev/null
        pid=$(ps axf | grep rgb_demo.py | grep -v grep | awk '{print $1}')
        echo -e "TRURN ON LED"
        (./rgb_interface.py -l ON)
        popd
        echo -e "$pid" > "${rgb_button_cache_folder}/rgb_demo_pid.dat"
    else
        pushd /home/pi/rpitools/gpio/rgb_led/bin/
        ./rgb_interface.py -l OFF
        popd
        killpid=$(ps axf | grep rgb_demo.py | grep -v grep | awk '{print $1}')
        echo -e "rgb_demo.py - pid $killpid KILL"
        kill "$killpid"
        echo -e "TRURN OFF LED"
    fi
}

function start_button_handler() {
    is_run_button_h=$(ps aux | grep [B]uttonHandler.py)
    if [ "$is_run_button_h" == "" ]
    then
        pushd /home/pi/rpitools/gpio/rgb_button/lib/
        (./ButtonHandler.py & > /dev/null)
        pid="$?"
        popd
        echo -e "$pid" > "${rgb_button_cache_folder}/button_handler_pid.dat"
    else
        echo -e "ButtonHandler.py already running."
    fi
}

start_button_handler
while true
do
        if [ -e "$button_event_path" ]
        then
            start_servive
            start_demo
            rm -f "$button_event_path"
        fi
        sleep .2
done

