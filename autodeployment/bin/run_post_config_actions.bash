#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

configure_transmission="${MYDIR_}/../lib/configure_transmission.bash"
configure_samba="${MYDIR_}/../lib/configure_samba.bash"

# transmission install config executor
echo -e "${YELLOW}RUN: configure_transmission ${NC}"
. "$configure_transmission"

# set samba configuration
echo -e "${YELLOW}RUN: configure_samba ${NC}"
. "$configure_samba"

# pixel install config executor
pixel_install="$($confighandler -s INSTALL_PIXEL -o action)"
if [ "$pixel_install" == "True" ] || [ "$pixel_install" == "true" ]
then
    echo -e "${YELLOW}RUN: PIXEL install ${NC}"
    . ${MYDIR_}/../../prepare/system/install_PIXEL.bash
else
    echo -e "${YELLOW}PIXEL install is not requested ${NC}"
fi

# vnc install config executor
vnc_install="$($confighandler -s INSTALL_VNC -o action)"
if [ "$vnc_install" == "True" ] || [ "$vnc_install" == "true" ]
then
    echo -e "${YELLOW}RUN: VNC install ${NC}"
    . ${MYDIR_}/../../prepare/system/install_vnc.bash
else
    echo -e "${YELLOW}VNC install is not requested ${NC}"
fi

# oled install config executor
oled_install="$($confighandler -s INSTALL_OLED -o action)"
if [ "$oled_install" == "True" ] || [ "$oled_install" == "true" ]
then
    echo -e "${YELLOW}RUN: OLED install ${NC}"
    python ${MYDIR_}/../../gpio/oled_128x64/bin/oled_interface.py -ss
else
    echo -e "${YELLOW}OLED install is not requested ${NC}"
fi

# run kodi config settings
echo -e "${YELLOW}RUN: KODI dektop icon and bootup start if set${NC}"
. ${MYDIR_}/../lib/kodi_runner.bash

# set dropbox halpage service if config requires
echo -e "${YELLOW}RUN: DROPBOX HALPAGE service setup${NC}"
. "/home/$USER/rpitools/tools/dropbox_halpage/systemd_setup/set_service.bash"
