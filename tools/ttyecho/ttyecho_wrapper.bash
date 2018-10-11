#!/bin/bash

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "${MYDIR}/make.bash"

echo -e "Actual tty (virtual console - teletype writer): $(tty)"
if [ "$#" -lt 2 ]
then
    echo -e "ttyecho: http://www.humbug.in/2010/utility-to-send-commands-or-data-to-other-terminals-ttypts/"
    echo -e "Example: ttyecho -n /dev/tty1 echo \"Welcome in rpitools\""
else
    sudo bash -c "${MYDIR}/ttyecho $*"
fi
