#!/bin/bash

# https://linuxhint.com/install_docker_on_raspbian_os/

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ERROR_CODES=0

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

source "${MYDIR}/../message.bash"
_msg_title="DOCKER SETUP"
source "$TERMINALCOLORS"

function exit_code_check() {
    local exitcode="$1"
    local title="$2"
    if [ "$exitcode" -ne 0 ]
    then
        _msg_  "\t[ ${RED}ERROR${NC} ] $title [$exitcode]"
        ERROR_CODES=$((ERROR_CODES + exitcode))
        exit "$exitcode"
    else
        _msg_ "\t[ ${GREEN}OK${NC} ] $title [$exitcode]"
    fi
}

_msg_ "Docker support in rpitools"

is_configured_cache_file="${MYDIR}/config/docker_config_done"

if [ -f "$is_configured_cache_file" ]
then
    _msg_ "Docker and docker-compose configuration was already done."
else
    _msg_ "Install Docker and docker-compose:"

    sudo apt-get install raspberrypi-kernel raspberrypi-kernel-headers -y
    exit_code_check "$?" "install: raspberrypi-kernel raspberrypi-kernel-headers"

    curl -sSL https://get.docker.com | sh
    exit_code_check "$?" "get: docker"

    sudo pip3 install docker-compose
    exit_code_check "$?" "install: docker-compose"

    echo -e "$(date)" > "$is_configured_cache_file"

    _msg_ "Reboot required..."
    sudo reboot
fi
sudo usermod -aG docker "${USER}"
exit_code_check "$?" "add ${USER} to docker user group"

if [ "$ERROR_CODES" -eq 0 ]
then
    _msg_ "DOCKER: ${GREEN}OK${NC}"
else
    _msg_ "DOCKER: ${RED}ERROR${NC}"
fi
