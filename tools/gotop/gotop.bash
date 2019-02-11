#!/bin/bash

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function gotop_handler() {
    if [ -e "${MYDIR}/gotop" ]
    then
        ${MYDIR}/gotop
    else
        pushd "$MYDIR"
            echo -e "Downloading ... gotop install at the first time."
            git clone --depth 1 https://github.com/cjbassi/gotop /tmp/gotop
            /tmp/gotop/scripts/download.sh
        popd
        gotop_handler
    fi
}

gotop_handler
