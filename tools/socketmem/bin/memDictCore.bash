#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

is_run="$(ps aux | grep -v grep | grep 'memDictCore.py')"
if [ "$is_run" == "" ]
then
    echo -e "Launch: memDictCore.py"
    python "${MYDIR}/../lib/memDictCore.py"
else
    echo -e "Already running: memDictCore.py"
fi
