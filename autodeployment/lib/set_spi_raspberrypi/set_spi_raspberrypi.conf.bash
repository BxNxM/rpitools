#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ACTION=false

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

source "${TERMINALCOLORS}"

source "${MYDIR}/../message.bash"
_msg_title="SPI SETUP"

conf_file_path="/etc/modules-load.d/raspberrypi.conf"
conf_file_path_moduls="/etc/modules"
if [ ! -e "$conf_file_path" ]
then
    _msg_ "Create file $conf_file_path (sudo echo \"\" > \"$conf_file_path\")"
    sudo /usr/bin/touch "$conf_file_path"
    sudo chmod 666 "$conf_file_path"
fi

function add_if_not_added() {
    local parameter="$1"
    local _conf_file_path="$2"
    local is_added=$(sudo grep -rnw "$_conf_file_path" -e "$parameter")
    if [ "$is_added" == "" ]
    then
        _msg_ "Add $parameter to $_conf_file_path"
        sudo echo "$parameter" >> "$_conf_file_path"
        ACTION=true
    fi
}

sudo chmod 666 "$conf_file_path"
sudo chmod 666 "$conf_file_path_moduls"
add_if_not_added "#spi-bcm2708" "$conf_file_path"
add_if_not_added "#spi-bcm2708" "$conf_file_path_moduls"

if [ "$ACTION" == "true" ]
then
    _msg_ "SPI was successfully configured."
else
    _msg_ "SPI bus was already configured"
fi
