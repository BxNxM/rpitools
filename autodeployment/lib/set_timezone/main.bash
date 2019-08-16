#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
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

source "${TERMINALCOLORS}"

source "${MYDIR}/../message.bash"
_msg_title="TIMEZONE SETUP"

TIMEZONE="$($CONFIGHANDLER -s GENERAL -o timezone)"

function info() {
    _msg_ "Get teh available timezones:"
    _msg_ "\ttimedatectl list-timezones"
    _msg_ "Search with typing: /"
}

function validate_and_get_full() {
    local TIMEZONE_BAK="$TIMEZONE"
    TIMEZONE="$(timedatectl list-timezones | grep ${TIMEZONE})"
    if [ "$TIMEZONE" == "" ]
    then
        VALID=false
        _msg_ "TIMEZONE INVALID: $TIMEZONE_BAK"
    else
        VALID=true
        _msg_ "TIMEZONE VALID: $TIMEZONE"
    fi
}

function set_timezone() {
    if [ "$VALID" == "true" ]
    then
        if [ "$(timedatectl status | grep ${TIMEZONE})" == "" ]
        then
            _msg_ "Set timezone: sudo timedatectl set-timezone ${TIMEZONE}"
            sudo bash -c "timedatectl set-timezone ${TIMEZONE}"
        else
            _msg_ "Timezone was already set: ${TIMEZONE}"
        fi
    fi
}

info
validate_and_get_full
set_timezone
