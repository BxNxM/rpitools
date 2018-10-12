#!/bin/bash

arg_len="$#"
arg_list=($@)

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "Retropie: https://retropie.org.uk" | lolcat
if [ "${arg_list[0]}" == "config" ] || [ "${arg_list[0]}" == "c" ]
then
    if [ -e "${MYDIR}/RetroPie-Setup/retropie_setup.sh" ]
    then
        echo -e "Execute: ${MYDIR}/RetroPie-Setup/retropie_setup.sh"
        sudo "${MYDIR}/RetroPie-Setup/retropie_setup.sh"
    else
        sudo apt-get install lsb-release
        pushd "$MYDIR"
            git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
            cd RetroPie-Setup
                chmod +x retropie_setup.sh
                sudo ./retropie_setup.sh
        popd
    fi
elif [ "${arg_list[0]}" == "start" ] || [ "${arg_list[0]}" == "s" ]
then
    if [ -e "/usr/bin/emulationstation" ]
    then
        echo -e "Execute: pkill x && /usr/bin/emulationstation &"
        pkill x && /usr/bin/emulationstation &
    else
        echo -e "Retropie was not installed, pls run: $MYPATH config"
    fi
elif [ "${arg_list[0]}" == "--help" ] || [ "${arg_list[0]}" == "-h" ] || [ "${arg_list[0]}" == "help" ] || [ "$arg_len" -eq 0 ]
then
    echo -e "Retropie wrapper:"
    echo -e "config | c"
    echo -e "start | s"
    echo -e "--help | -h | help"
fi
