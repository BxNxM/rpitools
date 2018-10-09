#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
glances_username="$($confighandler -s APACHE -o glances_username)"

echo -e $glances_username | /usr/bin/python /usr/local/bin/glances --webserver --disable-process --process-short-name --hide-kernel-threads --port 61208 --percpu --disable-irix -B 0.0.0.0 --username --password
