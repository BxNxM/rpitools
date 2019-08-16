#!/bin/bash

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

source "$TERMINALCOLORS"

CACHE_PATH_is_set="$REPOROOT/cache/.retropie_install_done"

source "${MYDIR}/../message.bash"
_msg_title="RETROPIE INSTALL"

_msg_ "Retropie on Raspbain: https://retropie.org.uk/docs/Manual-Installation/"

if [ ! -e "$CACHE_PATH_is_set" ]
then
    mkdir -p ${MYDIR}/retropie
    pushd ${MYDIR}/retropie
        _msg_ "Clone retropie-setup"
        git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
        cd RetroPie-Setup
        sudo chmod +x retropie_setup.sh
        _msg_ "Run retropie_setup.sh"
        sudo ./retropie_setup.sh
        if [ "$?" -eq 0 ]
        then
            echo -e "$(date)" > "$CACHE_PATH_is_set"
        fi
    popd
else
    _msg_ "Retropie was already installed: $CACHE_PATH_is_set exists."
    _msg_ "Configure with: sudo ${MYDIR}/retropie/RetroPie-Setup/retropie_setup.sh"
fi
