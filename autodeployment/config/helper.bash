#!/bin/bash

MYPATH_CONF="${BASH_SOURCE[0]}"
MYDIR_CONF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

template_config="${MYDIR_CONF}/rpitools_config_template.cfg"
custom_config="${MYDIR_CONF}/rpitools_config.cfg"

if [ ! -e "$custom_config" ]
then
    echo -e "$custom_config NOT EXISTS"
    echo -e "CREATE? [Y/N]"
    read option
    if [ "$option" == "Y" ] || [ "$option" == "y" ]
    then
        echo -e "cp $template_config -> $custom_config"
        cp "$template_config" "$custom_config"
    else
        echo -e "See you later ;) - see our git README.md file\nhttps://github.com/BxNxM/rpitools"
    fi
else
    echo -e "$custom_config EXISTS"
    echo -e "OPEN [Y/N] | DIFF [D]"
    read option
    if [ "$option" == "Y" ] || [ "$option" == "y" ]
    then
        vim "$custom_config"
    elif [ "$option" == "D" ]
    then
        echo -e "[INFO] change side: ctrl+w+w"
        echo -e "[INFO] exit all: :wqa"
        echo -e "[INFO] exit without saving all: :qa!"
        echo -e "GOT IT? [Y/N]"
        read option
        if [ "$option" == "Y" ] || [ "$option" == "y" ]
        then
            vimdiff -O "$custom_config" "$template_config"
        fi
    fi
fi
echo -e "Goodbye ;)"
