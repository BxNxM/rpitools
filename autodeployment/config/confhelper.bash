#!/bin/bash

MYPATH_CONF="${BASH_SOURCE[0]}"
MYDIR_CONF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

template_config="${MYDIR_CONF}/rpitools_config_template.cfg"
custom_config="${MYDIR_CONF}/rpitools_config.cfg"
source "${MYDIR_CONF}/../../prepare/colors.bash"

function question() {
    echo -e "${YELLOW}$1${NC}"
}

if [ ! -e "$custom_config" ]
then
    echo -e "$custom_config NOT EXISTS"
    question "CREATE? [Y/N]"
    read option
    if [ "$option" == "Y" ] || [ "$option" == "y" ]
    then
        echo -e "cp $template_config -> $custom_config"
        cp "$template_config" "$custom_config"
        vim "$custom_config"
    else
        question "See you later ;) - see our git README.md file\nhttps://github.com/BxNxM/rpitools"
    fi
else
    echo -e "$custom_config EXISTS"
    menu_text="OPEN [Y/N] | DIFF [D]"
    if [[ -z "$DEVICE" ]] || [[ "$DEVICE" != "RASPBERRY" ]]
    then
        menu_text+=" | IMPORT [I]"
    fi
    question "$menu_text"
    read option
    option_y_n_d="$option"
    if [ "$option" == "Y" ] || [ "$option" == "y" ]
    then
        vim "$custom_config"
    elif [ "$option" == "D" ] || [ "$option" == "d" ]
    then
        echo "[INFO] change side: ctrl+w+w"
        echo -e "[INFO] exit all: :wqa"
        echo -e "[INFO] exit without saving all: :qa!"
        question "GOT IT? [Y/N]"
        read option
        if [ "$option" == "Y" ] || [ "$option" == "y" ]
        then
            vimdiff -O "$custom_config" "$template_config"
        fi
    elif [ "$option" == "I" ] || [ "$option" == "i" ]
    then
        question "ADD YOUR CUSTOM CONFIG PATH HERE:"
        read existing_config_path
        if [ -f "$existing_config_path" ]
        then
            if [ -f "$custom_config" ]
            then
                echo -e "$custom_config EXISTS, before override backup:"
                echo -e "Copy $custom_config -> ~/Desktop/${custom_config}.BCKP"
                cp "$custom_config" ~/Desktop/$(basename $custom_config).BCKP
            fi
            echo -e "Copy: $existing_config_path -> $custom_config"
            cp "$existing_config_path" "$custom_config"
            if [ -f "$custom_config" ]
            then
                echo -e "\t${GREEN}SUCCESS${NC}"
            else
                echo -e "\t${RED}FAILED${NC}"
            fi
        else
            echo -e "${RED}NOT EXISTS:${NC} $existing_config_path"
        fi
    fi
fi

if [[ -z "$DEVICE" ]] || [[ "$DEVICE" == "RASPBERRY" ]]
then
    if [ "$option" == "Y" ] || [ "$option" == "y" ] || [ "$option" == "D" ] || [ "$option" == "d" ]
    then
        question "SAVE CHANGES? [Y] | [N]"
        read option
        if [[ "$option" == "Y" ]] || [[ "$option" == "y" ]]
        then
            (. /home/$USER/rpitools/tools/cache_restore_backup.bash backup)
        fi
    fi
fi
echo -e "Goodbye ;)"
