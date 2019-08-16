#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
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

source "${MYDIR}/../message.bash"

_msg_ "RUN apache basic setup based on rpi_config and rpitools/autodeployment/lib/apache_setup/template"
apache_override_underupdate_webpage="$($CONFIGHANDLER -s APACHE -o override_underupdate)"
if [[ "$apache_override_underupdate_webpage" == "True" ]] || [[ "$apache_override_underupdate_webpage" == "true" ]]
then
    _msg_ "\t override_underupdate: $apache_override_underupdate_webpage"
    ("${MYDIR}/setup_based_on_template.bash" "-f")
else
    _msg_ "\t override_underupdate: $apache_override_underupdate_webpage"
    ("${MYDIR}/setup_based_on_template.bash")
fi
