#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GITALISES_PATH="${MYDIR}/config/gitconfig.add"
GITCONFIG_PATH="$HOME/.gitconfig"

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

source "$TERMINALCOLORS"

CACHE_PATH_is_set="$REPOROOT/cache/.git_configure_is_done"

source "${MYDIR}/../message.bash"
_msg_title="GIT SETUP"

git_mail="$($CONFIGHANDLER -s MYGIT -o git_username)"
git_name="$($CONFIGHANDLER -s MYGIT -o git_mail)"
git_set_action="$($CONFIGHANDLER -s MYGIT -o activate)"


function add_git_aliases() {
    if [ "$(cat $GITCONFIG_PATH | grep 'alias')" == "" ]
    then
        _msg_ "Add git aliases"
        cat "$GITALISES_PATH" >> "$GITCONFIG_PATH"
    else
        _msg_ "Git aliases was already added"
    fi
}

if [ "$git_set_action" == "True" ] || [ "$git_set_action" == "true" ]
then
    _msg_ "SET MAIL ADDRESS: git config --global user.email ${git_mail}"
    git config --global user.email "${git_mail}"
    exit_code_mail="$?"
    _msg_ "SET USERNAME: git config --global user.name ${git_name}"
    git config --global user.name "${git_name}"
    exit_code_name="$?"
    add_git_aliases
    if [ "$exit_code_mail" == 0 ] && [ "$exit_code_name" == 0 ]
    then
        echo -e "$(date)" > "$CACHE_PATH_is_set"
    fi
else
    _msg_ "GIT SETUP NOT REQUESTED"
fi


