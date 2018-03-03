#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGAHNDLER="${MYDIR_}/../../autodeployment/bin/ConfigHandlerInterface.py"
CUSTOM_CONFIG="${MYDIR_}/../../autodeployment/config/rpitools_config.cfg"
username="pi"
hostname="$($CONFIGAHNDLER -s RPI_MODEL -o custom_hostname).local"

function copy_repo_to_rpi_machine() {
    rpitools_path="../../../rpitools"
    if [ -d "$rpitools_path" ]
    then
        echo -e "COPY: scp "$rpitools_path" pi@raspberrypi.local:/home/pi/"
        echo -e "Default PWD: raspberry"
        scp -r "$rpitools_path" pi@raspberrypi.local:/home/pi/
    fi
}

function copy_localmachine_ssh_pub_key_to_rpi_machine() {
    ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)"
    echo -e "Copy id_rsa.pub to raspberry known_hosts: $ssh_pub_key"
    ssh pi@raspberrypi.local "if [ ! -d /home/pi/.ssh ]; then mkdir /home/pi/.ssh; fi"
    ssh pi@raspberrypi.local "if [ ! -e '/home/pi/.ssh/authorized_keys' ]; then echo $ssh_pub_key > /home/pi/.ssh/authorized_keys; fi"
}

function execute_source_setup_on_rpi_machine() {
    ssh pi@raspberrypi.local 'cd rpitools && source setup'
}

function execute_source_setup_on_rpi_machine_custom_host() {
    ssh "${username}@${hostname}" 'cd rpitools && source setup'
}

function create_set_indicator_file() {
    ssh "${username}@${hostname}" "touch ~/rpitools/cache/.rpi_remote_config_done"
}

function waiting_for_up_again_after_reboot() {
    local host="$1"
    local retry=120
    sleep 2
    for ((i=0; i<${retry}; i++))
    do
        is_avaible_output="$(ping -c 3 ${host})"
        is_avaible="$?"
        echo -e "Wait for system up again: $host"
        if [ "$is_avaible" -eq 0 ]
        then
            echo -e "System is ready: $host"
            break
        fi
        sleep 2
    done
}

is_avaible_output="$(ping -c 2 raspberrypi.local)"
is_avaible_exitcode="$?"
if [ "$is_avaible_exitcode" -eq 0 ]
then
    echo -e "ssh-keygen -R raspberrypi.local"
    ssh-keygen -R raspberrypi.local
    is_rpi_machine_set=$(ssh pi@raspberrypi.local "if [ -e  ~/rpitools/cache/.rpi_remote_config_done ]; then echo 1; else echo 0; fi")
    custom_hostname_is_active=1
else
    echo -e "ssh-keygen -R $hostname"
    ssh-keygen -R "$hostname"
    is_rpi_machine_set=$(ssh "${username}@${hostname}" "if [ -e  ~/rpitools/cache/.rpi_remote_config_done ]; then echo 1; else echo 0; fi")
    custom_hostname_is_active=0
fi

if [ "$is_rpi_machine_set" == 0 ]
then
    if [ "$custom_hostname_is_active" -eq 1  ]
    then
        echo -e "remote Configure executing ;)"
        echo -e "\tcopy local machine ssh pub key to rpi machine for pwdless login"
        copy_localmachine_ssh_pub_key_to_rpi_machine
        echo -e "\tcopy_repo"
        copy_repo_to_rpi_machine
        echo -e "\texecute source setup"
        execute_source_setup_on_rpi_machine
        echo -e "waiting for reboot..."
        waiting_for_up_again_after_reboot "$hostname"
    fi

    # run until reboot is not happens
    for ((k=0; k<4; k++))
    do
        echo -e "\texecute source setup"
        execute_source_setup_on_rpi_machine_custom_host
        waiting_for_up_again_after_reboot "$hostname"
        sleep 1
    done

        echo -e "\tWE ARE DONE :D"
        create_set_indicator_file
else
    echo -e "remote settings are already done _@/\""
fi

