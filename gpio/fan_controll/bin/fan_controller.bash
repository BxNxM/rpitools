#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "${MYDIR}/../systemd_setup/set_service.bash"

if [ "$(sudo systemctl is-active temp_controll_fan)" != "active" ] && [ "$(sudo systemctl is-enabled temp_controll_fan)" == "enabled" ]
then
    python3 "${MYDIR}/../lib/fan_controller_core.py"
fi
