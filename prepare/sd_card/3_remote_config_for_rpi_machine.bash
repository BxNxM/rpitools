#!/bin/bash

# SSHPASS
# install on mac: brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
# install on linux: sudo apt-get-install sshpass

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGAHNDLER="${MYDIR_}/../../autodeployment/bin/ConfigHandlerInterface.py"
CUSTOM_CONFIG="${MYDIR_}/../../autodeployment/config/rpitools_config.cfg"
username="pi"
default_pwd="raspberry"
hostname="$($CONFIGAHNDLER -s GENERAL -o custom_hostname).local"
pixel_activate="$($CONFIGAHNDLER -s INSTALL_PIXEL -o activate)"
vnc_activate="$($CONFIGAHNDLER -s INSTALL_VNC -o activate)"
custom_pwd="$($CONFIGAHNDLER -s SECURITY -o os_user_passwd)"
reboot_wait_loop=8

# SET timer
SECONDS=0

if [ "$pixel_activate" == "False" ] || [ "$pixel_activate" == "false" ]
then
    reboot_wait_loop=$((reboot_wait_loop-1))
fi
if [ "$vnc_activate" == "False" ] || [ "$vnc_activate" == "false" ]
then
    reboot_wait_loop=$((reboot_wait_loop-1))
fi

function copy_repo_to_rpi_machine() {
    local cpwith="rsync"
    rpitools_path="${MYDIR_}/../../../rpitools"
    if [ -d "$rpitools_path" ]
    then
        if [ "$cpwith" == "scp" ]
        then
            echo -e "COPY: scp "$rpitools_path" pi@raspberrypi.local:/home/pi/"
            echo -e "Default PWD: raspberry"
            sshpass -p "$default_pwd" scp -r "$rpitools_path" "$username@raspberrypi.local:/home/$username/"
        elif [ "$cpwith" == "rsync" ]
        then
            echo -e "COPY: rsync -avz -e  \"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\" --progress \"$rpitools_path\" pi@raspberrypi.local:/home/pi"
            echo -e "Default PWD: raspberry"
            sshpass -p "$default_pwd" rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress "$rpitools_path" "$username@raspberrypi.local:/home/$username"
        fi
    fi
}

function copy_localmachine_ssh_pub_key_to_rpi_machine() {
    ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)"
    echo -e "Copy id_rsa.pub to raspberry known_hosts: $ssh_pub_key"
    sshpass -p "$default_pwd" ssh -o StrictHostKeyChecking=no pi@raspberrypi.local "if [ ! -d /home/pi/.ssh ]; then mkdir /home/pi/.ssh; fi"
    sshpass -p "$default_pwd" ssh -o StrictHostKeyChecking=no pi@raspberrypi.local "if [ ! -e '/home/pi/.ssh/authorized_keys' ]; then echo $ssh_pub_key > /home/pi/.ssh/authorized_keys; fi"
}

function execute_source_setup_on_rpi_machine() {
    sshpass -p "$default_pwd" ssh -o StrictHostKeyChecking=no pi@raspberrypi.local 'cd rpitools && source setup'
}

function execute_source_setup_on_rpi_machine_custom_host() {
    ssh -o StrictHostKeyChecking=no "${username}@${hostname}" 'cd rpitools && source setup'
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
    is_rpi_machine_set=$(sshpass -p "$default_pwd" ssh -o StrictHostKeyChecking=no pi@raspberrypi.local "if [ -e  ~/rpitools/cache/.instantiation_done ]; then echo 1; else echo 0; fi")
    custom_hostname_is_active=1
else
    echo -e "ssh-keygen -R $hostname"
    ssh-keygen -R "$hostname"
    is_rpi_machine_set=$(ssh -o StrictHostKeyChecking=no "${username}@${hostname}" "if [ -e  ~/rpitools/cache/.instantiation_done ]; then echo 1; else echo 0; fi")
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

    default_pwd="$custom_pwd"
    echo -e "ssh-keygen -R $hostname"
    ssh-keygen -R "$hostname"
    # run until reboot is not happens
    for ((k=0; k<${reboot_wait_loop}; k++))
    do
        echo -e "\texecute source setup"
        execute_source_setup_on_rpi_machine_custom_host
        waiting_for_up_again_after_reboot "$hostname"
        sleep 1
    done

        echo -e "\tWE ARE DONE :D"
        echo -e "\tElapsed time $(($SECONDS/60/60)):$(($SECONDS/60%60)):$(($SECONDS%60))"
        exit 0
else
    echo -e "remote settings are already done _@/\""
fi

