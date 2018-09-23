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
log_file_sizeMB_trigger="$($confighandler -s LOGROTATE -o log_file_size_mb_trigger)"
log_file_dayolder_trigger="$($confighandler -s LOGROTATE -o log_file_dayolder_trigger)"
run_period_sec="$($confighandler -s LOGROTATE -o run_period_sec)"

logs_folder="/var/log/"
logs_folder2="/var/log/"
find_size_over_Mb="$log_file_sizeMB_trigger"
sleeptime="$run_period_sec"
rotate_lines=50
black_list=("syslog" "daemon")

debugmsg=true
function debug_msg() {
    local msg="$*"
    if [ "$debugmsg" == "true" ]
    then
        echo -e "[$(date)]\t $msg"
    fi
        #echo -e "[$(date)]\t $msg" >> "$logfile"
}

function logs_to_clean_by_size() {
    local log_folder_path="$1"
    filtered_logs="$(sudo find "$log_folder_path" -size +"${find_size_over_Mb}"M)"
    filtered_logs=($filtered_logs)
    for log in "${filtered_logs[@]}"
    do
        for black in "${black_list[@]}"
        do
            if [[ "$log" == *"$black"* ]]
            then
                debug_msg "FILTERED FILE TO CLEAN: $log BIGGER THEN LIMIT [ $find_size_over_Mb Mb ]"
                rotate "$log"
            else
                debug_msg "UNKNOWN FILETERED LOG, to clean add it to the black list"
            fi
        done
    done
}

function logs_to_clean_older_then_x_days() {
    local log_folder_path="$1"
    files_older_then_x_days_list=($(find "${log_folder_path}" -mtime +"${log_file_dayolder_trigger}" -iname "*.log*" 2>/dev/null))
    for actual_log_file in "${files_older_then_x_days_list[@]}"
    do
        if [ "$(stat -c%s "$actual_log_file")" -gt 1 ]
        then
            debug_msg "Delete $actual_log_file older then ${log_file_dayolder_trigger} days."
            sudo rm -f "$actual_log_file"
        else
            debug_msg "Skipping delete $actual_log_file (older then ${log_file_dayolder_trigger}) but it is empty."
        fi
    done
}

function rotate() {
    local actual_log_path="$1"
    local tmp_log_path="/tmp/cache_log"
    debug_msg "Rotate log file: $actual_log_path last $rotate_lines lines."
    sudo tail -n "$rotate_lines" "$actual_log_path" > "$tmp_log_path"
    sudo rm -f "$actual_log_path"
    sudo mv "$tmp_log_path" "$actual_log_path"
    sudo chmod g+r "$actual_log_path"
}

###############################################
#                    MAIN                     #
###############################################
if [ ! -z "$option" ] && [ "$option" == "True" ]
then
    debug_msg "Run auto log cleaner in loop."
    while true
    do
        # clean logs
        logs_to_clean_by_size "$logs_folder"
        logs_to_clean_by_size "$logs_folder2"
        # clean procfs deleted files
        sudo logrotate -f /etc/logrotate.conf
        # clean fog files bu date
        logs_to_clean_older_then_x_days "$logs_folder"
        # sleep before run again
        sleep "$sleeptime"
    done
else
    debug_msg "Run auto log clenaer once."
    logs_to_clean_by_size "$logs_folder"
    logs_to_clean_by_size "$logs_folder2"
    logs_to_clean_older_then_x_days "$logs_folder"
fi
