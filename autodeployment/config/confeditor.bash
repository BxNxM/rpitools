#!/bin/bash

MYPATH_CONF="${BASH_SOURCE[0]}"
MYDIR_CONF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

arg_list=($@)
if [[ "${arg_list[*]}" == *"h"* ]] || [[ "${arg_list[*]}" == *"help"* ]]
then
    echo -e "==== QUICK COMANDS ===="
    echo -e "edit | e\t- edit configuration"
    echo -e "diff | d\t- diff configuration with template config"
    echo -e "OR RUN WITHOUT PARAMETERS, AND FOLLOW THE INSTRUCTIONS (RECOMMENDED)"
    exit 0
fi

template_config="${MYDIR_CONF}/rpitools_config_template.cfg"
custom_config="${MYDIR_CONF}/rpitools_config.cfg"
source "${MYDIR_CONF}/../../prepare/colors.bash"

function question() {
    echo -e "${YELLOW}$1${NC}"
}

function validate_conf() {
    if [ -f "${MYDIR_CONF}/rpitools_config.cfg" ]
    then
        local validate_msg=$(${MYDIR_CONF}/../bin/ConfigHandlerInterface.py -v)
        local exitcode="$?"
        if [[ "$validate_msg" == *"MISSING"* ]]
        then
            exitcode=$((exitcode+1))
        fi
        if [ "$exitcode" -eq 0 ]
        then
            echo -e "${GREEN}VALID: rpitools_config.cfg [$exitcode]${NC}"
        else
            echo -e "$validate_msg"
            echo -e "${RED}INVALID: rpitools_config.cfg [$exitcode]${NC}\nPls. solve config problems: confeditor -> D"
        fi
    fi
}
validate_conf

function import_configuration() {
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
            local validate_msg=$(${MYDIR_CONF}/../bin/ConfigHandlerInterface.py -v)
            local exitcode="$?"
            if [[ "$validate_msg" == *"MISSING"* ]]
            then
                exitcode=$((exitcode+1))
            fi
            if [ "$exitcode" -eq 0 ]
            then
                echo -e "\t${GREEN}IMPORT SUCCESS & VALIDATE OK! [$exitcode]${NC}"
            else
                echo -e "$validate_msg"
                echo -e "\t${RED}IMPORT SUCCESS & VALIDATE FAILED[$exitcode]${NC}\nPls. solve config problems: confeditor -> D"
            fi
        else
            echo -e "\t${RED}IMPORT FAILED!${NC}"
        fi
    fi
}

if [ ! -e "$custom_config" ]
then
    echo -e "$custom_config NOT EXISTS"
    question "CREATE? [Y/N] IMPORT? [I]"
    read option
    if [ "$option" == "Y" ] || [ "$option" == "y" ]
    then
        echo -e "cp $template_config -> $custom_config"
        cp "$template_config" "$custom_config"
        vim "$custom_config"
    elif [ "$option" == "I" ] || [ "$option" == "i" ]
    then
        import_configuration
    else
        question "See you later ;) - see our git README.md file\nhttps://github.com/BxNxM/rpitools"
    fi
else
    echo -e "$custom_config EXISTS"

    if [[ "${arg_list[*]}" == *"e"* ]] || [[ "${arg_list[*]}" == *"edit"* ]]
    then
        echo -e "QUICK ARG OPTION: edit"
        option="Y"
    elif [[ "${arg_list[*]}" == *"d"* ]] || [[ "${arg_list[*]}" == *"diff"* ]]
    then
        echo -e "QUICK ARG OPTION: diff"
        option="D"
    else
        menu_text="OPEN [Y/N] | DIFF [D]"
        if [[ ! -z "$DEVICE" ]] && [[ "$DEVICE" != "RASPBERRY" ]]
        then
            menu_text+=" | IMPORT [I]"
        fi
        question "$menu_text"
        read option
    fi

    if [ "$option" == "Y" ] || [ "$option" == "y" ]
    then
        vim "$custom_config"
    elif [ "$option" == "D" ] || [ "$option" == "d" ]
    then
        if [ "${#arg_list[@]}" -eq 0 ]
        then
            echo "[INFO] change side: ctrl+w+w"
            echo -e "[INFO] exit all: :wqa"
            echo -e "[INFO] exit without saving all: :qa!"
            question "GOT IT? [Y/N]"
            read option
        else
            option="Y"
        fi
        if [ "$option" == "Y" ] || [ "$option" == "y" ]
        then
            vimdiff -O "$custom_config" "$template_config"
        fi
    elif [ "$option" == "I" ] || [ "$option" == "i" ]
    then
        import_configuration
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
            question "APPLY MODIFICATIONS (source setup)? [Y] | [N]"
            read option_resource
            if [ "$option_resource" == "Y" ] || [ "$option_resource" == "y" ]
            then
                pushd ~/rpitools
                source setup
                popd
            fi
        fi
    fi
fi
echo -e "Goodbye ;)"
