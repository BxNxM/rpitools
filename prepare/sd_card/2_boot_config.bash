#!/bin/bash

#source colors
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

source "$TERMINALCOLORS"
source ${MYDIR}/../sub_elapsed_time.bash

CUSTOM_CONFIG="${REPOROOT}/autodeployment/config/rpitools_config.cfg"

# message handler function
function message() {
    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BROWN}[ boot config ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BROWN}[ boot config ]${NC} $msg" >> "${RRPITOOLS_LOG}"
    fi
}

# validate config:
config_stdout="$($CONFIGHANDLER -v)"
if [ "$?" -ne 0 ]
then
    message "$config_stdout"
    message "Config is invalid, to fix use: confeditor d"
    exit 1
fi

if [ "$OS" == "Darwin" ]
then
    message "Use MacOS settings."
    glob_boot_path="/Volumes/boot"
elif [ "$OS" == "GNU/Linux" ] || [ "$OS" == "Linux"  ]
then
    message "Use Linux settings."
    glob_boot_path="/media/$USER/boot/"
else
    message "This script work on Mac or Linux, this OS $OS is not supported!"
    exit 2
fi

function config_is_avaible() {
    if [ ! -e "$CUSTOM_CONFIG" ]
    then
        echo -e "Create custom config file - before run this script!"
        echo -e "cp ${REPOROOT}/autodeployment/config/rpitools_config_template.cfg  ${REPOROOT}/autodeployment/config/rpitools_config.cfg"
        echo -e "And edit this file!"
    fi
}

if [ -e "$glob_boot_path" ]
then
    # deault boot drive option
    message "DESAULT DISK IS AVAIBLE: $glob_boot_path"
    read -p 'Is it your disk, for configure? (y/n)' default_disk_conf
    if [ "$default_disk_conf" == "y" ]
    then
        sd_path="$glob_boot_path"
    fi
else
    # read sd card boot partition path
    message "Prepare SD card boot partition with enabling: ssh, eth-usb and wifi"
    read -p 'Your mounted boot disk path (on SD card): ' sd_path
    echo -e "DEBUG: $sd_path"
fi

function set_boot_config() {

    # check input path
    if [ ! -d "$sd_path" ] || [[ "$sd_path" != *"boot"* ]]
    then
        message "$sd_path is not a directory or not the sd card boot direcroty"
        sleep 5
        exit 1
    fi

    # generate file pathes
    #local config_path="${sd_path}/config.txt"
    local cmdline_path="${sd_path}/cmdline.txt"
    local ssh_en_path="${sd_path}/ssh"
    local wpa_supplicant_path="${sd_path}/wpa_supplicant.conf"

    # check generated file pathes
    if [ ! -e "$cmdline_path" ]
    then
        message "ERROR - $config_path and/or $cmdline_path not exists!"
        sleep 5
        exit 2
    fi

    #touch /Volumes/boot/ssh
    if [ ! -e "$ssh_en_path" ]
    then
        message "Make new file for enabling ssh [ SSH ]"
        echo "" > "$ssh_en_path"
    else
        message "$ssh_en_path is alredy set."
    fi

    # set wifi access
    ssid="$($CONFIGHANDLER -s NETWORK -o ssid)"
    passwd="$($CONFIGHANDLER -s NETWORK -o pwd)"
    if [ -e "$wpa_supplicant_path" ]
    then
        message "$wpa_supplicant_path is alredy set."
    else
        message "Set wifi in $wpa_supplicant_path [WIFI & NETWORK]"
        message "ssid: ${ssid} psk: ${passwd}"
        wpa_conf_templ='country=US\n'
        wpa_conf_templ+='ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n'
        wpa_conf_templ+='update_config=1\n'
        wpa_conf_templ+='\n'
        wpa_conf_templ+='network={\n'
        wpa_conf_templ+='    ssid="'"${ssid}"'"\n'
        wpa_conf_templ+='    psk="'"${passwd}"'"\n'
        wpa_conf_templ+='}'
        echo -e "$wpa_conf_templ" > "$wpa_supplicant_path"
    fi

    is_added=$(grep -rnw "$cmdline_path" -e "init=/usr/lib/raspi-config/init_resize.sh")
    if [ "$is_added" == "" ]
    then
        message "WARNING: don't forget to resize root partition with raspy-config"
    else
        message "Initial partition resize is enable :)"
    fi

    if [ -e "${MYDIR}/.drive" ]
    then
        drive="$(cat ${MYDIR}/.drive)"
        rm -f "${MYDIR}/.drive"

        if [ "$OS" == "Darwin" ]
        then
            message "Unmount drive: diskutil unmountDisk $drive"
            diskutil unmountDisk "$drive"
        else
            message "Unmount drive: umount $drive"
            umount "$drive"
        fi
    else
        message "Unmount disk manually, before unconnect [${MYDIR}/.drive disk info not exists, for auto-unmount]"
    fi

    message "[!!!] ONLY DO THESE STEP ONCE BEFORE FIRST BOOT [!!!]"
    read -p "Press ENTER, if you read and accept!"
}

echo "$(config_is_avaible)"
if [ "$(config_is_avaible)" == "" ]
then
    elapsed_time "start"
    set_boot_config
    elapsed_time "stop"
fi
