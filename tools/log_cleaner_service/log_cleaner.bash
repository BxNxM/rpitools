#!/bin/bash

arg_len="$#"
arg="$1"
if [ "$arg_len" -eq 1 ]
then
    if [ "$arg" == "-l" ] || [ "$arg" == "-loop" ]
    then
        option=True
    fi
fi

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
log_file_sizeGB_trigger="$($confighandler -s LOGROTATE -o log_file_sizegb_trigger)"
run_period_sec="$($confighandler -s LOGROTATE -o run_period_sec)"

logs_folder="/var/log/"
logs_folder2="/var/log/"
find_size_over_Gb="$log_file_sizeGB_trigger"
sleeptime="$run_period_sec"
rotate_lines=50
black_list=("syslog" "daemon")

debugmsg=true
function debug_msg() {
    local msg="$@"
    if [ "$debugmsg" == "true" ]
    then
        echo -e "[$(date)]\t $msg"
    fi
        #echo -e "[$(date)]\t $msg" >> "$logfile"
}

function logs_to_clean() {
    local log_folder_path="$1"
    filtered_logs="$(sudo find "$log_folder_path" -size +${find_size_over_Gb}G)"
    filtered_logs=($filtered_logs)
    for log in "${filtered_logs[@]}"
    do
        for black in "${black_list[@]}"
        do
            if [[ "$log" == *"$black"* ]]
            then
                debug_msg "FILTERED FILE TO CLEAN: $log BIGGER THEN LIMIT [ $find_size_over_Gb GB ]"
                rotate "$log"
            else
                debug_msg "UNKNOWN FILETERED LOG, to clean add it to the black list"
            fi
        done
    done
}

function rotate() {
    local actual_log_path="$1"
    debug_msg "Rotate log file: $actual_log_path"
    sudo tail -n "$rotate_lines" "$actual_log_path" > /var/log/cache_log
    sudo rm -f "$actual_log_path"
    sudo mv "/var/log/cache_log" "$actual_log_path"
    sudo chmod g+r "$actual_log_path"
}

if [ ! -z "$option" ] && [ "$option" == "True" ]
then
    debug_msg "Run auto log cleaner in loop."
    while true
    do
        # clean logs
        logs_to_clean "$logs_folder"
        logs_to_clean "$logs_folder2"
        # clean procfs deleted files
        sudo logrotate -f /etc/logrotate.conf
        # sleep before run again
        sleep "$sleeptime"
    done
else
    debug_msg "Run auto log clenaer once."
    logs_to_clean "$logs_folder"
    logs_to_clean "$logs_folder2"
fi
