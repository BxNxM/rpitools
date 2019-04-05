#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MEMDICT_CLIENT="${MYDIR}/../lib/clientMemDict.py"
NAMESPACE="general"
HEALTH=0

progress_status=0
function progress_indicator() {
    local progress=(".    " "..   " "...  " ".... " "....." "    ." "   .." "  ..." " ...." ".....")

    echo -n "${progress[$progress_status]}"
    progress_status=$(($progress_status+1))
    if [ "$progress_status" -eq ${#progress[@]} ] || [ "$progress_status" -gt "${#progress[@]}" ]
    then
        progress_status=0
    fi
    sleep .2
    #echo -ne "\033[2K"
    echo -ne "\r"
}

function console() {
    echo -e "[clinet memdict] $*"
}

function check_output_line_numbers_match() {
    local input=($@)
    local expected_line_number=${input[0]}
    local expected_line_number_extra=($(echo "$expected_line_number" | fold -w1))
    local operation="-eq"
    local lines=(${input[@]:1})

    if [ "${#expected_line_number_extra[@]}" -eq 2 ]
    then
        expected_line_number="${expected_line_number_extra[0]}"
        if [ "${expected_line_number_extra[1]}" == "+" ]
        then
            operation="-gt"
        elif [ "${expected_line_number_extra[1]}" == "-" ]
        then
            operation="-lt"
        elif [ "${expected_line_number_extra[1]}" == "=" ]
        then
            operation="-eq"
        else
            console "Wrong operation ${expected_line_number_extra[1]} +|-|="
            exit 1
        fi
    fi

    if [ "${#lines[@]}" "$operation" "$expected_line_number" ]
    then
        console "\tPASS"
    else
        console "\tFAIL"
        HEALTH=$(($HEALTH + 1))
    fi
}

function check_output_substring() {
    local output="$1"
    local substring="$2"

    console "Match substring: [$substring] with output."
    if [[ "$output" == *"$substring"* ]]
    then
        console "\tPASS"
    else
        console "\tFAIL"
    fi
}

function test_get_data_silence_False() {
    local substring="$1"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k born -s False"
    console "[test_get_data_silence_False] CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check_output_line_numbers_match "1+" "$output"
    if [ "$substring" != "" ]
    then
        check_output_substring "$output" "$substring"
    fi
}

function test_get_data_silence_True() {
    local substring="$*"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k born -s True"
    console "[test_get_data_silence_True] CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check_output_line_numbers_match "1" "$output"
    if [ "$substring" != "" ]
    then
        check_output_substring "$output" "$substring"
    fi
}

function run_thread_get_data() {
    local cnt=0
    local time_query_sec="$1"

    SECONDS=0
    while true
    do
        test_get_data_silence_True > /dev/null
        cnt=$(($cnt+1))
        if [ "$SECONDS" -gt "$time_query_sec" ]
        then
            break
        fi
    done
    console "\tREAD TEST: $cnt answer / $time_query_sec sec"
}

function test_get_data_parallel_silence_True() {
    local time_query_sec="$1"
    local thread="$2"
    local pid_list=()

    for ((i=0; i<"$thread"; i++))
    do
        run_thread_get_data "$time_query_sec" &
        pid="$!"
        console "[ $(($i+1))/$thread ] PID $pid"
        pid_list+=("$pid")
    done

    console "WAIT FOR THE PIDS..."
    while true
    do
    for pid in ${pid_list[@]}
    do
        if ps -p $pid > /dev/null
        then
            if [ -z "$end_progress_animation" ]
            then
                progress_indicator
            fi
        else
            if [ "$pid" -eq "${pid_list[0]}" ]
            then
                end_progress_animation=1
            fi
            if [ "$pid" -eq "${pid_list[-1]}" ]
            then
                is_break=1
                break
            fi
        fi
    done
    if [ ! -z "$is_break" ] && [ "$is_break" -eq 1 ]
    then
        break
    fi
    done

    # post check
    for pid in ${pid_list[@]}
    do
        wait "${pid_list[@]}"
    done
}


function main() {

    console "---------------------------------------------"
    console "------  SIMPLE DATA QUERY FROM MEMDICT  -----"
    console "---------------------------------------------"
    test_get_data_silence_False "around2018"
    console "---------------------------------------------"
    test_get_data_silence_True "around2018"

    console "---------------------------------------------"
    console "----  PARALLEL DATA QUERY FROM MEMDICT  -----"
    console "---------------------------------------------"
    # sample time, threads
    console "SAMPLE TIME: 1, THREADS: 100"
    test_get_data_parallel_silence_True 1 100
    console "SAMPLE TIME: 5, THREADS: 50"
    test_get_data_parallel_silence_True 5 50
}

main
if [ "$HEALTH" -eq 0 ]
then
    console "OVERALL HEALTH GOOD [$HEALTH]"
else
    console "OVERALL HEALTH BAD [$HEALTH]"
fi

exit "$HEALTH"
