#!/bin/bash

# SSHPASS
# install on mac: brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
# install on linux: sudo apt-get-install sshpass

#set -x

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

CUSTOM_CONFIG="${REPOROOT}/autodeployment/config/rpitools_config.cfg"
username="pi"
default_pwd="raspberry"
custom_hostname="$($CONFIGHANDLER -s GENERAL -o custom_hostname).local"
pixel_activate="$($CONFIGHANDLER -s INSTALL_PIXEL -o activate)"
vnc_activate="$($CONFIGHANDLER -s INSTALL_VNC -o activate)"
custom_pwd="$($CONFIGHANDLER -s SECURITY -o os_user_passwd)"
reboot_wait_loop=8

# validate config:
config_stdout="$($CONFIGHANDLER -v)"
if [ "$?" -ne 0 ]
then
    message "Config is invalid, to fix use: confeditor d"
    exit 1
fi

# SET timer
SECONDS=0

function copy_repo_to_rpi_machine() {
    local cpwith="rsync"
    rpitools_path="${REPOROOT}"
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
    echo -e "shpass -p $default_pwd ssh -o StrictHostKeyChecking=no pi@raspberrypi.local 'cd rpitools && ./setup.bash'"
    sshpass -p "$default_pwd" ssh -o StrictHostKeyChecking=no pi@raspberrypi.local 'cd rpitools && ./setup.bash'
}

function execute_source_setup_on_rpi_machine_custom_host() {
    echo -e "Execute: ssh -o StrictHostKeyChecking=no ${username}@${custom_hostname} 'cd rpitools && ./setup.bash'"
    ssh -o StrictHostKeyChecking=no "${username}@${custom_hostname}" 'cd rpitools && ./setup.bash'
}

function check_host() {
    local host="$1"
    while true
    do
        check_host_exitcode=1
        is_avaible_output="$(ping -c 2 $custom_hostname)"
        is_avaible_exitcode="$?"
        if [ "$is_avaible_exitcode" -eq 0 ]
        then
            if [ "$host" == "$custom_hostname" ]
            then
                echo -e "\t====> Custom hostname $custom_hostname is available"
                check_host_exitcode=0
            fi
            break
        fi
        is_avaible_output="$(ping -c 2 raspberrypi.local)"
        is_avaible_exitcode="$?"
        if [ "$is_avaible_exitcode" -eq 0 ]
        then
            if [ "$host" == "raspberrypi.local" ]
            then
                echo -e "\t====> Default hostname raspberrypi.local is available"
                check_host_exitcode=0
            fi
            break
        fi
    done
}

function check_instantiation_is_done() {
    check_host "$custom_hostname"
    if [ "$check_host_exitcode" -eq 0 ]
    then
        echo -e "ssh-keygen -R $custom_hostname"
        ssh-keygen -R "$custom_hostname"
        is_rpi_machine_set=$(sshpass -p "$custom_pwd" ssh -o StrictHostKeyChecking=no pi@$custom_hostname "if [ -e  ~/rpitools/cache/.instantiation_done ]; then echo 1; else echo 0; fi")
    else
        echo -e "ssh-keygen -R raspberrypi.local"
        ssh-keygen -R raspberrypi.local
        is_rpi_machine_set=$(sshpass -p "$default_pwd" ssh -o StrictHostKeyChecking=no pi@raspberrypi.local "if [ -e  ~/rpitools/cache/.instantiation_done ]; then echo 1; else echo 0; fi")
    fi
}

function waiting_for_up_again_after_reboot() {
    local timeout=120
    while true
    do
        echo -e "Wait for system up again ...[$timeout / 0]"
        is_avaible_output="$(ping -c 2 $custom_hostname)"
        is_avaible_exitcode="$?"
        check_host_exitcode=1
        if [ "$is_avaible_exitcode" -eq 0 ]
        then
            break
        fi
        is_avaible_output="$(ping -c 2 raspberrypi.local)"
        is_avaible_exitcode="$?"
        if [ "$is_avaible_exitcode" -eq 0 ]
        then
            break
        fi
        timeout=$(($timeout-1))
        if [ "$timeout" -lt 0 ] || [ "$timeout" -eq 0 ]
        then
            echo -e "Wait timeout.... restart raspberry pi and try again."
            break
        fi
    done
}

function instantiate_main() {
    check_instantiation_is_done
    if [ "$is_rpi_machine_set" == "0"  ] || [ "$is_rpi_machine_set" -eq 0  ]
    then
        # FIRST: copy ssh-key and rpitools repo
        check_host "raspberrypi.local"
        if [ "$check_host_exitcode" -eq 0 ]
        then
            # custom hostname was not set:
            echo -e "remote Configure executing ;)"
            echo -e "\tcopy local machine ssh pub key to rpi machine for pwdless login"
            copy_localmachine_ssh_pub_key_to_rpi_machine
            echo -e "\tcopy_repo"
            copy_repo_to_rpi_machine
        fi

        for ((k=0; k<${reboot_wait_loop}; k++))
        do
            check_instantiation_is_done
            if [ "$is_rpi_machine_set" -ne 0  ]
            then
                break
            fi

            check_host "raspberrypi.local"
            if [ "$check_host_exitcode" -eq 0 ]
            then
                echo -e "\texecute ./setup.bash on raspberrypi.local"
                execute_source_setup_on_rpi_machine
                waiting_for_up_again_after_reboot
            else
                echo -e "\texecute ./setup.bash on $custom_hostname"
                execute_source_setup_on_rpi_machine_custom_host
                waiting_for_up_again_after_reboot
            fi
        done
    fi
    echo -e "\tWE ARE DONE :D"
    echo -e "\tElapsed time $(($SECONDS/60/60)):$(($SECONDS/60%60)):$(($SECONDS%60))"
    exit 0
}

instantiate_main
