#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGAHNDLER="${MYDIR_}/../../autodeployment/bin/ConfigHandlerInterface.py"
CUSTOM_CONFIG="${MYDIR_}/../../autodeployment/config/rpitools_config.cfg"
CACHE_indicator_done_path="${MYDIR_}/../../cache/.initial_wpa_suppl_and_config_and_cmdline_txt_setup_done"
source ${MYDIR_}/../colors.bash
source ${MYDIR_}/../sub_elapsed_time.bash
wpa_supplicant_path="/etc/wpa_supplicant/wpa_supplicant.conf"
config_path="/boot/config.txt"
cmdline_path="/boot/cmdline.txt"

_msg_title="wpa_supplient - config.txt - cmdline.txt SETUP"
function _msg_() {
    local rpitools_log_path="${MYDIR_}/../../cache/rpitools.log"

    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ rpitools ]${NC} $_msg_title - $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ rpitools ]${NC} $_msg_title - $msg" >> "$rpitools_log_path"
    fi
}

# SUB FUNCTIONS
function change_parameter() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        _msg_ "cat $where | grep -v grep | grep $from\nis_set: $is_set"
        is_set="$( sudo cat "$where" | grep -v grep | grep "$from")"
        _msg_ "$is_set"
        if [ "$is_set" != "" ]
        then
            local cmd="sed -i \"s|${from}|${to}|g\" $where"
            _msg_ "sudo bash -c '$cmd'"
	    sudo bash -c "${cmd}"
        else
            _msg_ "${GREEN}Custom parameter $to already set in $where ${NC}"
        fi
    fi
}

# FUNCTIONS
function init_wpa_supplient() {
    local wpa_conf_templ=""
    local exitcode=0
    local e=0
    (sudo grep "country" "$wpa_supplicant_path")
    e="$?"
    exitcode=$((exitcode+e))
    (sudo grep "ctrl_interface" "$wpa_supplicant_path")
    e="$?"
    exitcode=$((exitcode+e))
    (sudo grep "update_config" "$wpa_supplicant_path")
    e="$?"
    exitcode=$((exitcode+e))
    if [ "$exitcode" -ne 0 ]
    then
        _msg_ "Init wpa supplient config"

        wpa_conf_templ='country=US\n'
        wpa_conf_templ+='ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n'
        wpa_conf_templ+='update_config=1\n'

        local tmp_wpa_data=${MYDIR_}/.wpa_tmp.dat
        echo -e "$wpa_conf_templ" > "$tmp_wpa_data"
        sudo bash -c "cat $wpa_supplicant_path $tmp_wpa_data > $wpa_supplicant_path"
        rm "$tmp_wpa_data"
    else
        _msg_ "wpa supplient init already done"
    fi
}

function set_wifi_wpa_data() {
   # set wifi access
    local ssid="$1"
    local passwd="$2"
    local wpa_conf_templ=""
    (sudo grep "$ssid" "$wpa_supplicant_path")
    local exitcode_ssid="$?"
    if [ -e "$wpa_supplicant_path" ] && [ "$exitcode_ssid" -eq 0 ]
    then
        _msg_ "$wpa_supplicant_path : $ssid is alredy set."
    else
        _msg_ "Set wifi in $wpa_supplicant_path [WIFI & NETWORK]"
        _msg_ "ssid: ${ssid} psk: ${passwd}"
        wpa_conf_templ+='network={\n'
        wpa_conf_templ+='    ssid="'"${ssid}"'"\n'
        wpa_conf_templ+='    psk="'"${passwd}"'"\n'
        wpa_conf_templ+='}'

        local tmp_wpa_data=${MYDIR_}/.wpa_tmp.dat
        echo -e "$wpa_conf_templ" > "$tmp_wpa_data"
        sudo bash -c "cat $wpa_supplicant_path $tmp_wpa_data >> $wpa_supplicant_path"
        rm "$tmp_wpa_data"
    fi
}

# CONFIG config.txt file
function configure_config_dot_txt_and_cmdline_dot_txt() {
    # SET USB ETHERNET IF TARGET IS RPI_ZERO
    rpi_module="$($CONFIGAHNDLER -s GENERAL -o model)"
    if [ "$rpi_module" == "rpi_zero" ]
    then
        #config.txt add -> dtoverlay=dwc2 <- end of the file
        is_added=$(grep -rnw "$config_path" -e "dtoverlay=dwc2")
        if [ "$is_added" == "" ]
        then
            _msg_ "Set $config_path file - add new line dtoverlay=dwc2 [ USB ETHERNET ]"
            sudo bash -c "echo -e '\n# Enable usb-ethernet\ndtoverlay=dwc2' >> $config_path"
        else
            _msg_ "In $config_path , dtoverlay=dwc2 is already set"
        fi

        #cmdline.txt add -> modules-load=dwc2,g_ether <- after rootwait, before quiet
        is_added=$(grep -rnw "$cmdline_path" -e "modules-load=dwc2,g_ether")
        if [ "$is_added" == "" ]
        then
            _msg_ "Set cmdline.txt after rootwait -> modules-load=dwc2,g_ether <- before quiet [ USB ETHERNET ]"
            change_parameter "rootwait" "rootwait modules-load=dwc2,g_ether" "$cmdline_path"
        else
            _msg_ "$cmdline_path is alredy set."
        fi
    fi

    #config.txt add -> gpu_mem=xyz <- end of the file
    is_added=$(grep -rnw "$config_path" -e "gpu_mem")
    if [ "$is_added" == "" ]
    then
        gpu_mem="$($CONFIGAHNDLER -s GENERAL -o required_gpu_mem)"
        _msg_ "Set $config_path file - add new line gpu_mem=$gpu_mem [ for video playing ]"
        sudo bash -c "echo -e '\n# Set GPU allocated memory\ngpu_mem=$gpu_mem' >> $config_path"
    else
        _msg_ "In $config_path , gpu_mem is already set"
    fi

    #config.txt add -> dtparam=i2c_arm=on <- end of the file
    is_added=$(grep -rnw "$config_path" -e "#dtparam=i2c_arm=on")
    if [ "$is_added" != "" ]
    then
        _msg_ "Set $config_path file - add new line dtparam=i2c_arm=on [ for i2c ]"
        change_parameter "#dtparam=i2c_arm=on" "dtparam=i2c_arm=on" "$config_path"
    else
        _msg_ "In $config_path , dtparam=i2c_arm=on is already set"
    fi

    # Add device_tree_param=i2c_arm=on to $config_path
    is_added=$(grep -rnw "$config_path" -e "device_tree_param=i2c_arm=on")
    is_added_=$(grep -rnw "$config_path" -e "#device_tree_param=i2c_arm=on")
    if [ "$is_added_" != "" ]
    then
        _msg_ "Change #device_tree_param=i2c_arm=on -> device_tree_param=i2c_arm=on in $config_path [ for i2c ]"
        change_parameter "#device_tree_param=i2c_arm=on" "device_tree_param=i2c_arm=on" $config_path
    fi
    if [ "$is_added" == "" ]
    then
        _msg_ "Add device_tree_param=i2c_arm=on to $config_path [ for i2c ]"
        sudo bash -c "echo -e '\n#I2C enable\ndevice_tree_param=i2c_arm=on' >> $config_path"
    else
        _msg_ "device_tree_param=i2c_arm=on is already set in $config_path"
    fi

    # set parameter in $cmdline_path for i2c enable
    is_enable=$(grep -rnw "$cmdline_path" -e "bcm2708.vc_i2c_override=1")
    if [ "$is_enable" == ""  ]
    then
        _msg_ "Add bcm2708.vc_i2c_override=1 to $cmdline_path [ for i2c ]"
        change_parameter 'rootwait' 'rootwait bcm2708.vc_i2c_override=1' "$cmdline_path"
    else
        _msg_ "bcm2708.vc_i2c_override=1 in $cmdline_path is already set."
    fi

    #config.txt add -> dtparam=spi=on <- end of the file
    is_added=$(grep -rnw "$config_path" -e "#dtparam=spi=on")
    if [ "$is_added" != "" ]
    then
        _msg_ "Set $config_path file - add new line #dtparam=spi=on [ for i2c ]"
        change_parameter "#dtparam=spi=on" "dtparam=spi=on" "$config_path"
    else
        _msg_ "In $config_path , dtparam=spi=on is already set"
    fi
}

function check_ssh_daemion() {
    if [ "$(systemctl is-enabled ssh)" != "enabled" ]
    then
        _msg_ "enable ssh service"
        sudo systemctl enable ssh
        if [ "$(systemctl is-active ssh)" != "active" ]
        then
            _msg_ "start ssh service"
            sudo systemctl start ssh
        fi
    fi
}

_msg_ "Configure system: wpa_supplient - config.txt - cmdline.txt"
if [ ! -e "$CACHE_indicator_done_path" ]
then
    _msg_ "\tConfiguration started..."

    init_wpa_supplient
    set_wifi_wpa_data "$($CONFIGAHNDLER -s NETWORK -o ssid)" "$($CONFIGAHNDLER -s NETWORK -o pwd)"

    configure_config_dot_txt_and_cmdline_dot_txt

    check_ssh_daemion

    echo -e "$(date)" > "$CACHE_indicator_done_path"
else
    _msg_ "\talready done: $CACHE_indicator_done_path exists."
fi