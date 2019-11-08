#!/bin/bash

#source colors
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

source "${TERMINALCOLORS}"

function basemessage() {
    # basemessage handler function
    local msg="$1"
    if [ ! -z "$msg" ]
    then
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ rpitools base ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ rpitools base ]${NC} $msg" >> "$RRPITOOLS_LOG"
    fi
}

function validate_config() {
    # validate custom - user config based on template
    "${CONFIGHANDLER}" -v
    exit_code="$?"
    if [ "$exit_code" -ne 0 ]
    then
        basemessage "Set your configuration berfore continue!\n${GREEN}confeditor, and press D${NC}"
        INVALID_CONFIG="TRUE"
    else
        basemessage "Your configuration is valid :D"
        INVALID_CONFIG="FALSE"
    fi
}

function main_pase() {

    if [ "$INVALID_CONFIG" == "FALSE" ]
    then
        "${REPOROOT}/prepare/system/configure_wpasupplient_and_configtxt_and_cmdlinetxt.bash"
        "${REPOROOT}/prepare/system/custom_user.bash"                   # default user - custom hostname
        basemessage "Set network interfaces for the expected behaviour"
        "${REPOROOT}/prepare/system/network/setup_network_interfaces.bash"
        "${REPOROOT}/prepare/system/hack_apt_sources.bash"

        # update once (first run ever) before install apps
        is_installed_file_indicator="$REPOROOT/cache/.first_boot_update_update_installed"
        if [ -e "$is_installed_file_indicator" ]
        then
            basemessage "After first boot update already done"
        else
            basemessage "Make updates after first boot."
            . ${REPOROOT}/prepare/system/install_updates.bash
            if [ "$?" -eq 0 ]
            then
               echo "$(date) First boot update done" > "$is_installed_file_indicator"
            else
                basemessage "ERROR: ${REPOROOT}/prepare/system/install_updates.bash"
            fi
        fi
        basemessage "Install requested programs from list ${REPOROOT}/template/programs.dat:"
        "${REPOROOT}/prepare/system/install_apps.bash"
        "${REPOROOT}/prepare/system/security.bash"
        "${REPOROOT}/prepare/system/set_system_wide_commands.bash"
    else
        basemessage "[WARNING] RPITOOLS CONFIG INVALID - SKIP BASE CONFIG"
    fi
}

validate_config
main_pase
