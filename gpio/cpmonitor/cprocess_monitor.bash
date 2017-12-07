#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function read_file() {
    local file="$1"
    local valid=false

    if [ ! -z "$file" ]
    then
        if [ -f "$file" ]
        then
            valid=true
        else
            echo -e "$file IS NOT EXISTS"
        fi
    else
        echo -e "No input for file read!"
    fi

    lineS=()
    if [ "$valid" == "true" ]
    then
        while IFS= read -r line || [[ "$line" ]]
        do
            lineS+=("$line")
        done < "$file"
    fi
}


function get_process_info() {
    p_name="$1"
    pid=$(ps aux | grep -v grep | grep $p_name | awk '{print $2}')
    cpu=$(ps aux | grep -v grep | grep $p_name | awk '{print $3}')
    mem=$(ps aux | grep -v grep | grep $p_name | awk '{print $4}')
    runtime=$(ps aux | grep -v grep | grep $p_name | awk '{print $10}')
    cmd=$(ps aux | grep -v grep | grep $p_name | awk '{print $11 $12}')
    if [ "$pid" != "" ]
    then
        echo -e "$pid\t\t$cpu\t\t$mem\t\t$runtime\t\t$p_name\t\t$cmd"
    else
        echo -e ""
    fi
}

read_file "${MYDIR}/process_list"
echo -e "PID\t\tCPU\t\tMEM\t\tRUNTIME\t\tNAME\t\t\t\tCMD"
for proc in "${lineS[@]}"
do
    get_process_info "$proc"
done
