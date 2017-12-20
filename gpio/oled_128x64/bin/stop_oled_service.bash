#!/bin/bash

function soft_kill() {
    process_name="oled_gui_core.py"
    process=($(ps aux | grep -v grep | grep "$process_name"))
    pid=${process[1]}
    kill -SIGINT "$pid"    #kill -2
}

function hard_kill() {
    process_name="oled_gui_core.py"
    process=($(ps aux | grep -v grep | grep "$process_name"))
    pid=${process[1]}
    kill -SIGKILL "$pid"    #kill -9
}

soft_kill
sleep 2
hard_kill

