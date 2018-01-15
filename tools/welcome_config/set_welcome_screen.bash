#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

config1="welcomeColor.dat"
config2=".profile"

if [ ! -e "${HOME}/${config1}" ]
then
    echo -e "COPY COLOR SET: ${MYDIR}/${config1} -> ${HOME}/${config1}"
    cp "${MYDIR}/${config1}" "${HOME}/${config1}"

    if [ ! -e "${HOME}/${config2}_bckp" ]
    then
        echo -e "COPY CUSTOM .profile: ${MYDIR}/${config2} -> ${HOME}/${config2}"
        echo -e "\tbackup original .profile: ${HOME}/${config2} -> ${HOME}/${config2}_bckp"
        mv "${HOME}/${config2}" "${HOME}/${config2}_bckp"
        rm -f "${HOME}/${config2}"
        cp "${MYDIR}/${config2}" "${HOME}/${config2}"
    else
        echo -e ".profile file is alredy set: ${HOME}/${config2}_bckp are exists!"
    fi
else
    echo -e "Welcome command line screen is already set in .profile"
fi
