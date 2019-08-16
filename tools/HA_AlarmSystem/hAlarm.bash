#!/bin/bash

# script path n name
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

sysmonitor_log="${MYDIR}/sysmonitor_last.log"
mail_file_path="${MYDIR}/mail_alarm.dat"
cycle_sleep_time=20

function get_check_period_sec() {
    local cycle_sleep_time_="$($CONFIGHANDLER -s HALARM -o check_period_sec)"
    if [ "$cycle_sleep_time_" != "-undef-option" ]
    then
        if [ "$cycle_sleep_time_" -gt 5 ]
        then
            cycle_sleep_time="$cycle_sleep_time_"
        else
            cycle_sleep_time=5
        fi
    fi
}

function write_email_notifier_text() {
    local sysmonitor_printout_path="$1"
    local get_memdict_system_text="$($CLIENTMEMDICT -md -n system)"
    local title="RPITOOLS_SYSTEM_NOTIFY_-_NO_REPLY"

    if [[ "$get_memdict_system_text" == *"ALARM"* ]]
    then
        echo -e "ALARM WAS FOUND: WRITE MAIL CONTENT..."
        echo -e "$title" > "$mail_file_path"
        echo -e "$get_memdict_system_text" >> "$mail_file_path"
        echo -e "$(cat $sysmonitor_printout_path)" >> "$mail_file_path"
    fi
}

while true
do
    get_check_period_sec
    echo -e "QUERY SYSTEM HEALTH DATA [CYCLE $cycle_sleep_time SEC]"
    sysmonitor "-e" > "$sysmonitor_log"
    if [ "$?" -eq 0 ]
    then
        echo -e "\tsuccessful execution... wait $cycle_sleep_time sec"
        write_email_notifier_text "$sysmonitor_log"
    else
        echo -e "\tfailed execution... wait $cycle_sleep_time sec"
    fi
    sleep "${cycle_sleep_time}"
done
