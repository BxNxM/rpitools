#!/bin/bash

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

function elapsed_time() {
    local rpitools_log_path="${RRPITOOLS_LOG}"
    if [ -d "$cache_path" ]
    then
        if [ ! -f  "$rpitools_log_path" ]
        then
            echo "" > "$rpitools_log_path"
        fi
    fi

    option="$1"                 #start - stop

    if [ "$option" == "start" ]
    then
        SECONDS=0
    fi

    if [ "$option" == "stop" ]
    then
        duration=$SECONDS
        echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed." | tee -a "$rpitools_log_path"
    fi

    if [ "$option" != "stop" ] && [ "$option" != "start" ]
    then
        echo -e "INVALID OPTION: $option (VALID: start or stop)" | tee -a "$rpitools_log_path"
    fi
}

#elapsed_time "start"
#sleep 5
#elapsed_time "stop"
