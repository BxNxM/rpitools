#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "${MYDIR}/../systemd_setup/set_service.bash"
#python3 "${MYDIR}/../lib/fan_controller_core.py"
