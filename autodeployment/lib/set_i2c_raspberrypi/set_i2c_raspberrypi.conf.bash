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
_msg_title="I2C SETUP"

conf_file_path="/etc/modules-load.d/raspberrypi.conf"
if [ ! -e "$conf_file_path" ]
then
    _msg_ "Create file $conf_file_path (sudo echo \"\" > \"$conf_file_path\")"
    sudo /usr/bin/touch "$conf_file_path"
    sudo chmod 666 "$conf_file_path"
fi

function add_if_not_added() {
    local parameter="$1"
    local is_added=$(sudo grep -rnw "$conf_file_path" -e "$parameter")
    if [ "$is_added" == "" ]
    then
        _msg_ "Add $parameter to $conf_file_path"
        sudo echo "$parameter" >> "$conf_file_path"
        ACTION=true
    fi
}

sudo chmod 666 "$conf_file_path"
add_if_not_added "i2c-bcm2708"
add_if_not_added "i2c-dev"

if [ "$ACTION" == "true" ]
then
    _msg_ "Reboot after configure I2C required."
    sudo reboot now
else
    _msg_ "I2C bus was already configured"
fi
