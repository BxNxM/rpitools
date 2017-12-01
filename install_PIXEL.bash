#!/bin/bash

#source colors
source colors.bash

# message handler function
function message() {

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${GREEN}[ PIXEL GUI ]${NC} $msg"
    fi
}

function check_exitcode() {
    local status="$1"
    if [ "$status" -ne 0 ]
    then
        message "ERROR: $status"
        exit 2
    fi
}

# check we are sourced up
if [ -z "$REPOROOT" ]
then
    message "Please ${RED}source rpitools/setup${NC} before use these script!"
    exit 1
else
    if [ "$OS" != "GNU/Linux" ]
    then
        message "This script work on raspbian, this OS $OS is not supported!"
        exit 2
    fi
fi

is_installed_file_indicator=${REPOROOT}/cache/.PIXEL_installed
x11_config=/etc/X11/Xwrapper.config

if [ -f "$is_installed_file_indicator" ]
then
    message "PIXEL GUI is already installed"
else

    message "install: sudo apt-get update"
    echo "Y" | sudo apt-get update
    check_exitcode "$?"

    message "install: sudo apt-get install --no-install-recommends xserver-xorg"
    echo "Y" | sudo apt-get install --no-install-recommends xserver-xorg
    check_exitcode "$?"

    message "install: sudo apt-get install --no-install-recommends xinit"
    echo "Y" | sudo apt-get install --no-install-recommends xinit
    check_exitcode "$?"

    message "install: sudo apt-get install raspberrypi-ui-mods"
    echo "Y" | sudo apt-get install raspberrypi-ui-mods
    check_exitcode "$?"

    message "install: sudo apt-get install --no-install-recommends raspberrypi-ui-mods lxterminal gvfs"
    echo "Y" | sudo apt-get install --no-install-recommends raspberrypi-ui-mods lxterminal gvfs
    check_exitcode "$?"

    message "install: sudo apt-get install --reinstall libraspberrypi0 libraspberrypi-{bin,dev,doc} raspberrypi-bootloader"
    echo "Y" | sudo apt-get install --reinstall libraspberrypi0 libraspberrypi-{bin,dev,doc} raspberrypi-bootloader
    check_exitcode "$?"

    message "install: sudo usermod -a -G tty pi && sudo apt-get install xserver-xorg-legacy"
    echo "Y" | sudo usermod -a -G tty pi && sudo apt-get install xserver-xorg-legacy
    check_exitcode "$?"

    if [ ! -f "$x11_config" ]
    then
        config_text="allowed_users = anybody\nneeds_root_rights = no"
        echo -e "$config_text" > "$x11_config"
        echo -e "$config_text" | sudo tee "$x11_config"
    else
        status=$(grep -rnw "$x11_config" -e "allowed_users=console")
        if [ "$status" != "" ]
        then
            message "Configure $x11_config for allowed_users=anybody"
            sed -i "s/allowed_users=console/allowed_users=anybody/g" "$x11_config"
            check_exitcode "$?"
        fi

        status=$(grep -rnw "$x11_config" -e "allowed_users = console")
        if [ "$status" != "" ]
        then
            message "Configure $x11_config for allowed_users = anybody"
            sed -i "s/allowed_users = console/allowed_users = anybody/g" "$x11_config"
            check_exitcode "$?"
        fi
    fi

    echo "$(date) PIXEL was installed" > "$is_installed_file_indicator"

    message "REBOOT..."
    sleep 3
    sudo reboot
fi
