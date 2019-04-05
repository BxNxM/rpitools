#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MEMDICT_CLIENT="${MYDIR}/../lib/clientMemDict.py"
NAMESPACE="general"
HEALTH=0

function console() {
    echo -e "[clinet memdict] $*"
}

function check() {
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

function test_get_data_silence_False() {
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k born -s False"
    console "[test_get_data_silence_False] CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check "1+" "$output"
}

function test_get_data_silence_True() {
    local cmd="${MEMDICT_CLIENT} -md -n ${NAMESPACE} -k born -s True"
    console "[test_get_data_silence_True] CMD: $cmd"
    output=$($cmd)
    console "[output]\n|$output|"
    check "1" "$output"
}

function main() {
    console "---------------------------------------------"
    test_get_data_silence_False
    console "---------------------------------------------"
    test_get_data_silence_True
}

main
if [ "$HEALTH" -eq 0 ]
then
    console "OVERALL HEALTH GOOD [$HEALTH]"
else
    console "OVERALL HEALTH BAD [$HEALTH]"
fi

exit "$HEALTH"
