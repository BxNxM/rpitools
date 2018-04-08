#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

configure_transmission="${MYDIR_}/../lib/configure_transmission.bash"
set_transmission_whitelist_autoedit="/home/$USER/rpitools/tools/auto_restart_transmission/systemd_setup/set_service.bash"
configure_samba="${MYDIR_}/../lib/configure_samba.bash"

_msg_title="CONFIG POST ACTIONS"
function _msg_() {
    local msg="$1"
    echo -e "${YELLOW}[ $_msg_title ]${NC} - $msg"
}

# transmission install config executor
_msg_ "RUN: configure_transmission"
(. "$configure_transmission")
_msg_ "RUN: set transmission autorestart edit whitelist"
(. "$set_transmission_whitelist_autoedit")

# set samba configuration
_msg_ "RUN: configure_samba"
(. "$configure_samba")

# pixel install config executor
pixel_install="$($confighandler -s INSTALL_PIXEL -o action)"
if [ "$pixel_install" == "True" ] || [ "$pixel_install" == "true" ]
then
    _msg_ "RUN: PIXEL install"
    (. ${MYDIR_}/../../prepare/system/install_PIXEL.bash)
else
    _msg_ "PIXEL install is not requested"
fi

# vnc install config executor
vnc_install="$($confighandler -s INSTALL_VNC -o action)"
if [ "$vnc_install" == "True" ] || [ "$vnc_install" == "true" ]
then
    _msg_ "RUN: VNC install"
    (. ${MYDIR_}/../../prepare/system/install_vnc.bash)
else
    _msg_ "VNC install is not requested"
fi

# oled install config executor
oled_install="$($confighandler -s INSTALL_OLED -o action)"
if [ "$oled_install" == "True" ] || [ "$oled_install" == "true" ]
then
    _msg_ "RUN: OLED install"
    python ${MYDIR_}/../../gpio/oled_128x64/bin/oled_interface.py -ss
else
    _msg_ "OLED install is not requested"
fi

# run kodi config settings
_msg_ "RUN: KODI dektop icon and bootup start if set"
(. /home/$USER/rpitools/autodeployment/lib/kodi_runner.bash)

# set dropbox halpage service if config requires
_msg_ "RUN: DROPBOX HALPAGE service setup"
(. "/home/$USER/rpitools/tools/dropbox_halpage/systemd_setup/set_service.bash")

# Configure git
(. "/home/$USER/rpitools/autodeployment/lib/configure_git.bash")
