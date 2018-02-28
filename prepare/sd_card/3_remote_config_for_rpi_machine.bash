#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function copy_repo_to_rpi_machine() {
    rpitools_path="../../../rpitools"
    if [ -d "$rpitools_path" ]
    then
        echo -e "COPY: scp "$rpitools_path" pi@raspberrypi.local:/home/pi/"
        echo -e "Default PWD: raspberry"
        ssh-keygen -R raspberrypi.local
        scp -r "$rpitools_path" pi@raspberrypi.local:/home/pi/
    fi
}

function copy_localmachine_ssh_pub_key_to_rpi_machine() {
    ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)"; ssh pi@raspberrypi.local "echo $ssh_pub_key > ~/.ssh/authorized_keys"
}

function execute_source_setup_on_rpi_machine() {
    ssh pi@raspberrypi.local 'cd rpitools && source setup'
}

function create_set_indicator_file() {
    ssh pi@raspberrypi.local "touch ~/rpitools/cache/.rpi_remote_config_done"
}

is_rpi_machine_set=$(ssh pi@raspberrypi.local "if [ -e  ~/rpitools/cache/.rpi_remote_config_done ]; then echo 1; else echo 0; fi")
if [ "$is_rpi_machine_set" == 0 ]
then
    echo -e "remote Configure executing ;)"
    echo -e "\tcopy_repo"
    copy_repo_to_rpi_machine
    echo -e "\tcopy local machine ssh pub key to rpi machine for pwdless login"
    copy_localmachine_ssh_pub_key_to_rpi_machine
    echo -e "\texecute source setup"
    execute_source_setup_on_rpi_machine

    echo -e "\tWE ARE DONE :D"
    create_set_indicator_file
else
    echo -e "remote settings are already done _@/\""
fi

