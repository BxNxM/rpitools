#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

configure_transmission="${MYDIR_}/../lib/configure_transmission.bash"

echo -e "${YELLOW}RUN: configure_transmission ${NC}"
. "$configure_transmission"

pixel_install="$($confighandler -s INSTALL_PIXEL -o action)"
if [ "$pixel_install" == "True" ]
then
    echo -e "${YELLOW}RUN: PIXEL install ${NC}"
    . ${MYDIR_}/../../prepare/system/install_PIXEL.bash
else
    echo -e "${YELLOW}PIXEL install is not requested ${NC}"
fi

vnc_install="$($confighandler -s INSTALL_VNC -o action)"
if [ "$vnc_install" == "True" ]
then
    echo -e "${YELLOW}RUN: VNC install ${NC}"
    . ${MYDIR_}/../../prepare/system/install_vnc.bash
else
    echo -e "${YELLOW}VNC install is not requested ${NC}"
fi

oled_install="$($confighandler -s INSTALL_OLED -o action)"
if [ "$oled_install" == "True" ]
then
    echo -e "${YELLOW}RUN: OLED install ${NC}"
    python ${MYDIR_}/../../gpio/oled_128x64/bin/oled_interface.py -ss
else
    echo -e "${YELLOW}OLED install is not requested ${NC}"
fi
