#!/bin/bash

conf_file_path="/etc/modules-load.d/raspberrypi.conf"
if [ ! -e "$conf_file_path" ]
then
    echo "" > "$conf_file_path"
fi

function add_if_not_added() {
    local parameter="$1"
    local is_added=$(grep -rnw "$conf_file_path" -e "$parameter")
    if [ "$is_added" == "" ]
    then
        echo -e "Add $parameter to $conf_file_path"
        echo "$parameter" >> "$conf_file_path"
    fi
}

add_if_not_added "i2c-bcm2708"
add_if_not_added "i2c-dev"
