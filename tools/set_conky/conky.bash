#!/bin/bash

# more info about conky: https://www.novaspirit.com/2017/02/23/desktop-widget-raspberry-pi-using-conky/
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

rpimodel="$($CONFIGHANDLER -s GENERAL -o model)"
conky_conf_pi_zero=".conkyrc_pizero"
conky_conf_pi_3=".conkyrc_pi3"
if [ "$rpimodel" == "rpi_zero" ]
then
    conky_conf_to_set="$conky_conf_pi_zero"
else
    conky_conf_to_set="$conky_conf_pi_3"
fi

# set DISPLAY=:0 if xinit is run
xinitrx_is_run=$(ps aux | grep "[x]initrc")
if [ "$xinitrx_is_run" != "" ]
then
    # set display environment (for PIXEL startx)
    message "Set DISPLAY env - gui is run"
    export DISPLAY=:0
fi

# check conky config
if [ ! -e ~/.conkyrc ]
then
    echo -e "Copy conky configuration: ${MYDIR}/${conky_conf_to_set} -> ~/.conkyrc"
    cp "${MYDIR}/${conky_conf_to_set}" "$HOME/.conkyrc"
else
    echo -e "~/.conkyrc is already set"
fi


is_run=$(ps aux | grep -v grep | grep -v "conky.bash" | grep "conky")
echo -e "->|${is_run}|<-"

if [ "$is_run" == "" ]
then
    echo -e "Run conky"
    (conky) &
    exit 0
else
    echo -e "Conky is already run"
fi
