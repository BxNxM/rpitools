#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

wecome_color="welcomeColor.dat"
profile_path="/home/$USER/.profile"
welcome_screen_cmd="${MYDIR}/welcome_screen.bash"
welcome_screen_cmd=${welcome_screen_cmd/$USER/'$USER'}

if [ ! -e "${HOME}/${wecome_color}" ]
then
    echo -e "COPY COLOR SET: ${MYDIR}/${wecome_color} -> ${HOME}/${wecome_color}"
    cp "${MYDIR}/${wecome_color}" "${HOME}/${wecome_color}"
else
    echo -e "COLOR SET ALREADY DONE: ${HOME}/${wecome_color}"
fi

wecome_screen_is_set="$(cat $profile_path | grep -v grep | grep $welcome_screen_cmd)"
if [ "$wecome_screen_is_set" == "" ]
then
    echo -e "SET WELCOME SCREEN SCRIPT CALL: $welcome_screen_cmd IN $profile_path"
    echo -e "# welcome screen pintout call\n. $welcome_screen_cmd" >> "$profile_path"
else
    echo -e "$profile_path WELCOME COMMAND CALL IS ALREADY SET: $welcome_screen_cmd"
fi
