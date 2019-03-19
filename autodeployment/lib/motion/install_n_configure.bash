#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
motion_target_folder="$($confighandler -s MOTION -o target_folder)"
motion_activate="$($confighandler -s MOTION -o activate)"
http_username="$($confighandler -s MOTION -o http_user)"
http_password="$($confighandler -s MOTION -o http_pawwd)"
link_to_apche="$($confighandler -s MOTION -o link_under_apache)"

source "${MYDIR}/../../../prepare/colors.bash"
motion_conf_path="/etc/motion/motion.conf"              # https://tutorials-raspberrypi.com/raspberry-pi-security-camera-livestream-setup/
motion_conf_path2="/etc/default/motion"                 # start_motion_daemon=yes
add_modeprobe_to="/etc/modules-load.d/raspberrypi.conf"
initial_config_done_indicator="/home/$USER/rpitools/cache/.motion_initial_config_done"

# source apache path env
source "${MYDIR}/../apache_setup/apache.env"
apache_web_shared_folder="$APACHE_PRIVATE_SHARED_FOLDER"

source "${MYDIR}/../message.bash"
_msg_title="MOTION SETUP"

function change_line() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        _msg_ "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        is_set="$(sudo cat "$where" | grep -v grep | grep "$to")"
        _msg_ "$is_set"
        if [ "$is_set" == "" ]
        then
            _msg_ "${GREEN}Set parameter (full line): $to  (from: $from) ${NC}"
            #sudo sed -i 's|'"${from}"'\c|'"${to}"'|g' "$where"
            sudo sed -i '/'"${from}"'/c\'"${to}"'' "$where"
        else
            _msg_ "${GREEN}Custom config line $to already set in $where ${NC}"
        fi
    fi
}

function install() {
    output=$(command -v "motion")
    if [ -z "$output" ]
    then
        _msg_ "Install motion (camera handler service)."
        sudo apt-get install motion -y
    else
        _msg_ "motion is already installed."
    fi
}

function set_motion_permissions() {
    sudo chgrp motion "$motion_target_folder"
    chmod g+rwx "$motion_target_folder"
}

function create_motion_dir() {
    if [ ! -d "$motion_target_folder" ]
    then
        _msg_ "Create and set $motion_target_folder"
        mkdir -p "$motion_target_folder"
        set_motion_permissions
    else
        _msg_ "$motion_target_folder already exists."
        set_motion_permissions
    fi
}

function configure() {
    if [ "$(cat "$add_modeprobe_to" | grep 'bcm2835-v4l2')" == "" ]
    then
        _msg_ "Add / Activate kernel module: bcm2835-v4l2"
        sudo modprobe bcm2835-v4l2
        echo -e "bcm2835-v4l2\n" >> "$add_modeprobe_to"
    else
        _msg_ "Kernel module bcm2835-v4l2 already added and avtivated."
    fi

    _msg_ "Get camera details:"
    camera_details="$(v4l2-ctl -V)"
    _msg_ "$camera_details"

    _msg_ "Override $motion_conf_path conf file."
    sudo cp -f ${MYDIR}/motion.conf $motion_conf_path

    change_line "target_dir RPITOOLSREPALCEtargetdir" "target_dir ${motion_target_folder}" "$motion_conf_path"
    change_line "stream_authentication HTTPuser:HTTPpwd" "stream_authentication ${http_username}:${http_password}" "$motion_conf_path"

    _msg_ "Edit $motion_conf_path2 conf."
    change_line "start_motion_daemon=no" "start_motion_daemon=yes" "$motion_conf_path2"

    create_motion_dir

    sudo chmod +rw+r+r ${MYDIR}/motion.conf
    sudo chown root $motion_conf_path
    sudo chgrp root $motion_conf_path
}

function backup_official_configs() {
    mkdir -p "${MYDIR}/factory_confs"
    sudo cp "$motion_conf_path" "${MYDIR}/factory_confs"
    sudo cp "$motion_conf_path2" "${MYDIR}/factory_confs"
}

function execute() {
    _msg_ "START MOTION: sudo systemctl start motion"
    sudo service motion start
    #sudo systemctl start motion
    #sudo systemctl enable motion
}

function link_motionfolder_to_apache() {
    if [[ "$link_to_apche" == "True" ]] || [[ "$link_to_apche" == "true" ]]
    then
        local target_path="${apache_web_shared_folder}/$(basename $motion_target_folder)"
        local source_path="$motion_target_folder"
        if [ ! -e "$target_path" ]
        then
            _msg_ "Create link: $source_path -> $target_path"
            sudo ln -s $source_path $target_path
        else
            _msg_ "$source_path -> $target_path already exists."
        fi
    else
        if [[ "$motion_target_folder" != "" ]] && [[ "$target_path" == *"$(basename $motion_target_folder)"* ]]
        then
            _msg_ "Remove $target_path"
            if [ -e "$target_path" ]
            then
                sudo rm -f "$target_path"
            fi
        else
            _msg_ "Cant remove: $target_path ... [WARNING]"
        fi
    fi
}

if [[ "$motion_activate" == "true" ]] || [[ "$motion_activate" == "True" ]]
then
    create_motion_dir
    _msg_ "Motion install and config required"
    if [ ! -f "$initial_config_done_indicator" ]
    then
        install
        backup_official_configs
        configure
        echo -e "$(date)" > "$initial_config_done_indicator"
    else
        _msg_ "Initial install and config done, $initial_config_done_indicator exists."
    fi
    execute
elif [[ "$motion_activate" == "false" ]] || [[ "$motion_activate" == "False" ]]
then
    _msg_ "Motion install and configured NOT required"
    sudo systemctl stop motion
    sudo systemctl disable motion
else
    _msg_ "Invalid parameter: $motion_activate => True or False"
fi

link_motionfolder_to_apache
