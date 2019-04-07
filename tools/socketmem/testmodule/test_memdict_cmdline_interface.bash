#!/bin/bash

ARG_LIST=($@)

# SETTINGS
STAB_CAP_TEST=0
if [[ "$ARG_LIST[*]" == *"-h"* ]] || [[ "$ARG_LIST[*]" == *"--help"* ]]
then
    echo -e "-s | --stab\t run capacity and stability tests too"
    exit 0
elif [[ "$ARG_LIST[*]" == *"-s"* ]] || [[ "$ARG_LIST[*]" == *"--stab"* ]]
then
    STAB_CAP_TEST=1
fi

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MEMDICT_CLIENT="${MYDIR}/../lib/clientMemDict.py"
NAMESPACE="general"
FIELD="metadata"
HEALTH=0

source "${MYDIR}/colors.bash"

# ================================= TOOLS ====================================#
progress_status=0
function progress_indicator() {
    local progress=(".    " "..   " "...  " ".... " "....." "    ." "   .." "  ..." " ...." ".....")

    echo -n "${progress[$progress_status]}"
    progress_status=$(($progress_status+1))
    if [ "$progress_status" -eq ${#progress[@]} ] || [ "$progress_status" -gt "${#progress[@]}" ]
    then
        progress_status=0
    fi
    sleep .1
    #echo -ne "\033[2K"
    echo -ne "\r"
}

function console() {
    echo -e "${PURPLE}[clinet memdict]${NC} $*"
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
        console "\t${GREEN}PASS${NC}"
    else
        console "\t${RED}FAIL${NC}"
        HEALTH=$(($HEALTH + 1))
    fi
}

function check_output_substring() {
    local output="$1"
    local substring="$2"

    console "Match substring: [$substring] with output."
    if [[ "$output" == *"$substring"* ]]
    then
        console "\t${GREEN}PASS${NC}"
    else
        console "\t${RED}FAIL${NC}"
        HEALTH=$(($HEALTH + 1))
    fi
}

# ================================= TESTS ====================================#
function test_get_data_silence_False() {
    local substring="$1"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k born -s False"
    console "${YELLOW}[test_get_data_silence_False]${NC} CMD: $cmd"
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
    console "${YELLOW}[test_get_data_silence_True]${NC} CMD: $cmd"
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
        #console "[ $(($i+1))/$thread ] PID $pid"
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

function test_write_data_silence_False() {
    local substring="$1"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k service -s True"
    default_value=$($cmd)
    console "Default value: $default_value"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k service -v $substring -s False"
    console "${YELLOW}[test_write_data_silence_False]${NC} CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check_output_line_numbers_match "1+" "$output"
    if [ "$substring" != "" ]
    then
        check_output_substring "$output" "$substring"
    fi
    console "Restore default value: $default_value"
    "${MEMDICT_CLIENT}" -md -n "${NAMESPACE}" -k service -v "$default_value" -s True
}

function test_write_data_silence_True() {
    local substring="$1"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k service -s True"
    default_value=$($cmd)
    console "Default value: $default_value"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k service -v $substring -s True"
    console "${YELLOW}[test_write_data_silence_False]${NC} CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check_output_line_numbers_match "1" "$output"
    if [ "$substring" != "" ]
    then
        check_output_substring "$output" "True"
    fi
    console "Restore default value: $default_value"
    "${MEMDICT_CLIENT}" -md -n "${NAMESPACE}" -k service -v "$default_value" -s True
}

function run_thread_write_data() {
    local cnt=0
    local time_query_sec="$1"

    SECONDS=0
    while true
    do
        test_write_data_silence_True > /dev/null
        cnt=$(($cnt+1))
        if [ "$SECONDS" -gt "$time_query_sec" ]
        then
            break
        fi
    done
    console "\tWRITE TEST: $(($cnt*2)) write / $time_query_sec sec"
}

function test_write_data_parallel_silence_True() {
    local time_query_sec="$1"
    local thread="$2"
    local pid_list=()

    for ((i=0; i<"$thread"; i++))
    do
        run_thread_write_data "$time_query_sec" &
        pid="$!"
        #console "[ $(($i+1))/$thread ] PID $pid"
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

function test_get_field_data_silence_True() {
    local substring="$*"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -f ${FIELD} -k dummykey -s True"
    console "${YELLOW}[test_get_field_data_silence_True]${NC} CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check_output_line_numbers_match "1" "$output"
    if [ "$substring" != "" ]
    then
        check_output_substring "$output" "$substring"
    fi
}

function test_write_field_data_silence_True() {
    local substring="$1"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -f ${FIELD} -k dummykey -s True"
    default_value=$($cmd)
    console "Default value: $default_value"
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -f ${FIELD} -k dummykey -v $substring -s True"
    console "${YELLOW}[test_write_field_data_silence_True]${NC} CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check_output_line_numbers_match "1" "$output"
    if [ "$substring" != "" ]
    then
        check_output_substring "$output" "True"
    fi
    console "Restore default value: $default_value"
    "${MEMDICT_CLIENT}" -md -n "${NAMESPACE}" -f ${FIELD} -k dummykey -v "$default_value" -s True
}

function main() {

    console "-------------------------------------------------"
    console "--------  ${PURPLE}SIMPLE DATA QUERY FROM MEMDICT${NC}  -------"
    console "-------------------------------------------------"
    test_get_data_silence_False "around2018"
    console "---------------------------------------------"
    test_get_data_silence_True "around2018"


    console "-------------------------------------------------"
    console "--------  ${PURPLE}SIMPLE DATA WRITE TO MEMDICT${NC}  -------"
    console "-------------------------------------------------"
    test_write_data_silence_False "rpitools_write_testX"
    console "---------------------------------------------"
    test_write_data_silence_True "rpitools_write_testY"


    console "-------------------------------------------------"
    console "-  ${PURPLE}SIMPLE DATA READ FROM MEMDICT FIELD (metadata)${NC}  -"
    console "-------------------------------------------------"
    test_get_field_data_silence_True "dummyvalue"

    console "-------------------------------------------------"
    console "-  ${PURPLE}SIMPLE DATA WRITE FROM MEMDICT FIELD (metadata)${NC}  -"
    console "-------------------------------------------------"
    test_write_field_data_silence_True "dummyvalue_new"

    if [ "$STAB_CAP_TEST" == "1" ]
    then
        console "-------------------------------------------------"
        console "------  ${PURPLE}PARALLEL DATA QUERY FROM MEMDICT${NC}  -------"
        console "-------------------------------------------------"
        # sample time, threads
        console "${YELLOW}[READ] SAMPLE TIME: 1, THREADS: 100${NC}"
        test_get_data_parallel_silence_True 1 100
        console "---------------------------------------------"
        console "${YELLOW}[READ] SAMPLE TIME: 5, THREADS: 50${NC}"
        test_get_data_parallel_silence_True 5 50
        console "---------------------------------------------"
        console "${YELLOW}[READ] SAMPLE TIME: 1, THREADS: 6${NC}"
        test_get_data_parallel_silence_True 1 6


        console "-------------------------------------------------"
        console "------  ${PURPLE}PARALLEL DATA WRITE FROM MEMDICT${NC}  -------"
        console "-------------------------------------------------"
        console "${YELLOW}[WRITE] SAMPLE TIME: 5, THREADS: 3${NC}"
        test_write_data_parallel_silence_True 5 3
        console "---------------------------------------------"
        console "${YELLOW}[WRITE] SAMPLE TIME: 5, THREADS: 10${NC}"
        test_write_data_parallel_silence_True 5 10
    fi
}

main

console "-------------------------------------------------"
console "------  ${PURPLE}=========== SUMMARY =========${NC}  -------"
console "-------------------------------------------------"
if [ "$HEALTH" -eq 0 ]
then
    console "${YELLOW}OVERALL HEALTH ${GREEN}GOOD${NC} [$HEALTH]"
else
    console "${YELLOW}OVERALL HEALTH ${RED}PROBLEMATIC${NC} [$HEALTH]"
fi

console "${YELLOW}SHOW MEMDICT CONTENT${NC}"
${MEMDICT_CLIENT} -sh -s True
console "${YELLOW}SHOW MEMDICT STATISTIC${NC}"
${MEMDICT_CLIENT} -st -s True

exit "$HEALTH"
