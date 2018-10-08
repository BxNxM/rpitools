#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.retropie_install_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

source "${MYDIR_}/message.bash"
_msg_title="RETROPIE INSTALL"

_msg_ "Retropie on Raspbain: https://retropie.org.uk/docs/Manual-Installation/"

if [ ! -e "$CACHE_PATH_is_set" ]
then
    mkdir -p ${MYDIR_}/retropie
    pushd ${MYDIR_}/retropie
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
    _msg_ "Configure with: sudo ${MYDIR_}/retropie/RetroPie-Setup/retropie_setup.sh"
fi
