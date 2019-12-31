#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

git_mail="$($CONFIGHANDLER -s MYGIT -o git_mail)"
git_name="$($CONFIGHANDLER -s MYGIT -o git_username)"
git_set_action="$($CONFIGHANDLER -s MYGIT -o activate)"

# =============================================================== #
#                          SERVER SETUP                           #
# =============================================================== #
function smart_config_patch() {
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/gitconfig.data" "init" "{MAIL}" "$git_mail"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/gitconfig.data" "add" "{NAME}" "$git_name"
    "${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$GITCONFIG_PATH" "$MYDIR/config/" "gitconfig.finaltemplate" "gitconfig.data" "gitconfig.final" "gitconfig.patch"
    local exitcode="$?"
    if [ "$exitcode" -eq 255 ]
    then
        skip_actions=true
    fi
}

if [ "$git_set_action" == "True" ] || [ "$git_set_action" == "true" ]
then
    _msg_ "SET MAIL ADDRESS: git config --global user.email ${git_mail}"
    _msg_ "SET USERNAME: git config --global user.name ${git_name}"

    # WORKAROUND - no default config for git - store default as gitconfig.factory
    if [ ! -f "$GITCONFIG_PATH" ]
    then
        cp "$MYDIR/config/gitconfig.factory" "$GITCONFIG_PATH"
    fi

    smart_config_patch
    cp "$MYDIR/config/gitconfig.final" "$GITCONFIG_PATH"
    if [ ! -f "$GITCONFIG_PATH" ]
    then
        _msg_ "$GITCONFIG_PATH set failed!"
    fi

else
    _msg_ "GIT SETUP NOT REQUESTED"
fi


