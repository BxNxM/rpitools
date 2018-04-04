#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.git_configure_is_done"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

git_mail="$($confighandler -s MYGIT -o git_username)"
git_name="$($confighandler -s MYGIT -o git_mail)"
git_set_action="$($confighandler -s MYGIT -o action)"

_msg_title="GIT SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
}

if [ ! -e "$CACHE_PATH_is_set" ]
then

    if [ "$git_set_action" == "True" ] || [ "$git_set_action" == "true" ]
    then
        _msg_ "SET MAIL ADDRESS: git config --global user.email ${git_mail}"
        git config --global user.email "${git_mail}"
        exit_code_mail="$?"
        _msg_ "SET USERNAME: git config --global user.name ${git_name}"
        git config --global user.name "${git_name}"
        exit_code_name="$?"
        if [ "$exit_code_mail" == 0 ] && [ "$exit_code_name" == 0 ]
        then
            echo -e "$(date)" > "$CACHE_PATH_is_set"
        fi
    else
        _msg_ "GIT SETUP NOT REQUESTED"
    fi
else
    _msg_ "GIT IS ALREADY SET"
fi


