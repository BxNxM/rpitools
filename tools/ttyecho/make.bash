#!/bin/bash

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -e "${MYDIR}/ttyecho" ]
then
    pushd "${MYDIR}"
        gcc -O3 -o ttyecho ttyecho.c
    popd
fi
