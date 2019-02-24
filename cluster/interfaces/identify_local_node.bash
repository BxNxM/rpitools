#!/bin/bash

# https://www.jeffgeerling.com/blogs/jeff-geerling/controlling-pwr-act-leds-raspberry-pi

function progress_indicator() {
    local spin=("-" "|")
    for sign in "${spin[@]}"
    do
        echo -ne "\b${sign}"
        sleep .2
    done
    echo -ne "\b"
}

function show_heartbeat() {
    # Set the PWR LED to GPIO mode (set 'off' by default).
    echo gpio | sudo tee /sys/class/leds/led1/trigger

    # Set the ACT LED to trigger on cpu0 instead of mmc0 (SD card access).
    echo cpu0 | sudo tee /sys/class/leds/led0/trigger

    while true
    do
        # (Optional) Turn on (1) or off (0) the PWR LED.
        echo 1 | sudo tee /sys/class/leds/led1/brightness > /dev/null
        sleep .4
        echo 0 | sudo tee /sys/class/leds/led1/brightness > /dev/null
        progress_indicator &
        sleep .2
    done
}

function restore_factory_settings() {
    echo -e "Restore factory setting"

    # Revert the PWR LED back to 'under-voltage detect' mode.
    echo input | sudo tee /sys/class/leds/led1/trigger

    # Set the ACT LED to trigger on cpu0 instead of mmc0 (SD card access).
    echo mmc0 | sudo tee /sys/class/leds/led0/trigger
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "** Trapped CTRL-C"
        restore_factory_settings
        exit 0
}

show_heartbeat
