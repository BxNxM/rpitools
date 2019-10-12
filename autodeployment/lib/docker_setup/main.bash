#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

function exit_code_check() {
    local exitcode="$1"
    local title="$2"
    if [ "$exitcode" -ne 0 ]
    then
        echo -e  "\t[ ERROR ] $title [$exitcode]"
        exit "$exitcode"
    else
        echo -e "\t[ OK ] $title [$exitcode]"
    fi
}

echo -e "Execute test main script"

is_configured_cache_file="${MYDIR}/config/docker_config_done"

if [ -f "$is_configured_cache_file" ]
then
    echo -e "Docker config was already done."
else
    sudo apt-get install raspberrypi-kernel raspberrypi-kernel-headers -y
    exit_code_check "$?" "install: raspberrypi-kernel raspberrypi-kernel-headers"

    curl -sSL https://get.docker.com | sh
    exit_code_check "$?" "get: docker"

    echo -e "$(date)" > "$is_configured_cache_file"
fi
sudo usermod -aG docker "${USER}"
exit_code_check "$?" "add ${USER} to docker user group"

