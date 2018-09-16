#!/bin/bash

#source colors
MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGAHNDLER="${MYDIR_}/../../autodeployment/bin/ConfigHandlerInterface.py"
CUSTOM_CONFIG="${MYDIR_}/../../autodeployment/config/rpitools_config.cfg"
source ${MYDIR_}/../colors.bash
source ${MYDIR_}/../sub_elapsed_time.bash

# message handler function
function message() {
    local rpitools_log_path="${MYDIR_}/../../cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BROWN}[ boot config ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BROWN}[ boot config ]${NC} $msg" >> "$rpitools_log_path"
    fi
}

OS=$(uname)
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
        echo -e "cp ${MYDIR_}/../../autodeployment/config/rpitools_config_template.cfg  ${MYDIR_}/../../autodeployment/config/rpitools_config.cfg"
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
    if [ ! -e "$config_path" ] || [ ! -e "$cmdline_path" ]
    then
        message "ERROR - $config_path and/or $cmdline_path not exists!"
        sleep 5
        exit 2
    fi

    ## SET USB ETHERNET IF TARGET IS RPI_ZERO
    #rpi_module="$($CONFIGAHNDLER -s GENERAL -o model)"
    #if [ "$rpi_module" == "rpi_zero" ]
    #then
    #    #config.txt add -> dtoverlay=dwc2 <- end of the file
    #    is_added=$(grep -rnw "$config_path" -e "dtoverlay=dwc2")
    #    if [ "$is_added" == "" ]
    #    then
    #        message "Set $config_path file - add new line dtoverlay=dwc2 [ USB ETHERNET ]"
    #        echo -e "\n# Enable usb-ethernet\ndtoverlay=dwc2" >> "$config_path"
    #    else
    #        message "In $config_path , dtoverlay=dwc2 is already set"
    #    fi

    #    #cmdline.txt add -> modules-load=dwc2,g_ether <- after rootwait, before quiet
    #    is_added=$(grep -rnw "$cmdline_path" -e "modules-load=dwc2,g_ether")
    #    if [ "$is_added" == "" ]
    #    then
    #        message "Set cmdline.txt after rootwait -> modules-load=dwc2,g_ether <- before quiet [ USB ETHERNET ]"
    #        sed "s/rootwait/rootwait modules-load=dwc2,g_ether/g" "$cmdline_path" > "${cmdline_path}_edeted"
    #        mv "${cmdline_path}_edeted" "$cmdline_path"
    #    else
    #        message "$cmdline_path is alredy set."
    #    fi
    #fi

    ##config.txt add -> gpu_mem=xyz <- end of the file
    #is_added=$(grep -rnw "$config_path" -e "gpu_mem")
    #if [ "$is_added" == "" ]
    #then
    #    gpu_mem="$($CONFIGAHNDLER -s GENERAL -o required_gpu_mem)"
    #    message "Set $config_path file - add new line gpu_mem=$gpu_mem [ for video playing ]"
    #    echo -e "\n# Set GPU allocated memory\ngpu_mem=$gpu_mem" >> "$config_path"
    #else
    #    message "In $config_path , gpu_mem is already set"
    #fi

    ##config.txt add -> dtparam=i2c_arm=on <- end of the file
    #is_added=$(grep -rnw "$config_path" -e "#dtparam=i2c_arm=on")
    #if [ "$is_added" != "" ]
    #then
    #    message "Set $config_path file - add new line dtparam=i2c_arm=on [ for i2c ]"
    #    #echo -e "\n# I2C enabled\ndtparam=i2c_arm=on" >> "$config_path"
    #    change_parameter "#dtparam=i2c_arm=on" "dtparam=i2c_arm=on" "$config_path"
    #else
    #    message "In $config_path , dtparam=i2c_arm=on is already set"
    #fi

    ## Add device_tree_param=i2c_arm=on to $config_path
    #is_added=$(grep -rnw "$config_path" -e "device_tree_param=i2c_arm=on")
    #is_added_=$(grep -rnw "$config_path" -e "#device_tree_param=i2c_arm=on")
    #if [ "$is_added_" != "" ]
    #then
    #    echo -e "Change #device_tree_param=i2c_arm=on -> device_tree_param=i2c_arm=on in $config_path [ for i2c ]"
    #    change_parameter "#device_tree_param=i2c_arm=on" "device_tree_param=i2c_arm=on" $config_path
    #fi
    #if [ "$is_added" == "" ]
    #then
    #    echo -e "Add device_tree_param=i2c_arm=on to $config_path [ for i2c ]"
    #    echo -e "\n#I2C enable\ndevice_tree_param=i2c_arm=on" >> "$config_path"
    #else
    #    echo -e "device_tree_param=i2c_arm=on is already set in $config_path"
    #fi

    ## set parameter in $cmdline_path for i2c enable
    #is_enable=$(grep -rnw "$cmdline_path" -e "bcm2708.vc_i2c_override=1")
    #if [ "$is_enable" == ""  ]
    #then
    #    echo -e "Add bcm2708.vc_i2c_override=1 to $cmdline_path [ for i2c ]"
    #    #echo "bcm2708.vc_i2c_override=1" >> "$cmdline_path"
    #    change_parameter "quiet" "bcm2708.vc_i2c_override=1 quit" "$cmdline_path"
    #else
    #    echo -e "bcm2708.vc_i2c_override=1 in $cmdline_path is already set."
    #fi

    ##config.txt add -> dtparam=spi=on <- end of the file
    #is_added=$(grep -rnw "$config_path" -e "#dtparam=spi=on")
    #if [ "$is_added" != "" ]
    #then
    #    message "Set $config_path file - add new line #dtparam=spi=on [ for i2c ]"
    #    #echo -e "\n# SPI enabled\ndtparam=spi=on" >> "$config_path"
    #    change_parameter "#dtparam=spi=on" "dtparam=spi=on" "$config_path"
    #else
    #    message "In $config_path , dtparam=spi=on is already set"
    #fi

    #touch /Volumes/boot/ssh
    if [ ! -e "$ssh_en_path" ]
    then
        message "Make new file for enabling ssh [ SSH ]"
        echo "" > "$ssh_en_path"
    else
        message "$ssh_en_path is alredy set."
    fi

    # set wifi access
    ssid="$($CONFIGAHNDLER -s NETWORK -o ssid)"
    passwd="$($CONFIGAHNDLER -s NETWORK -o pwd)"
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
    message "Unmount sd card and put it to the raspberry pi."

    is_added=$(grep -rnw "$cmdline_path" -e "init=/usr/lib/raspi-config/init_resize.sh")
    if [ "$is_added" == "" ]
    then
        message "WARNING: don't forget to resize root partition with raspy-config"
    else
        message "Initial partition resize is enable :)"
    fi

    message "[!!!] ONLY DO THESE STEP ONCE BEFORE FIRST BOOT [!!!]"
    read -p "Press ENTER, if you read and accept!"
}

function change_parameter() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        echo -e "cat $where | grep -v grep | grep $from\nis_set: $is_set"
        is_set="$( cat "$where" | grep -v grep | grep "$from")"
        echo -e "$is_set"
        if [ "$is_set" != "" ]
        then
            message "sed \"s|${from}|${to}|g\" \"$where\" > \"${where}_edeted\""
            sed 's|'"${from}"'|'"${to}"'|g' "$where" > "${where}_edeted"
            mv "${where}_edeted" "$where"
        else
            echo -e "${GREEN}Custom parameter $to already set in $where ${NC}"
        fi
    fi
}

echo "$(config_is_avaible)"
if [ "$(config_is_avaible)" == "" ]
then
    elapsed_time "start"
    set_boot_config
    elapsed_time "stop"
fi
