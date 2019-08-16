#!/bin/bash

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

source "$TERMINALCOLORS"

motion_action_stream_forward="$($CONFIGHANDLER -s APACHE_MOTION_STREAM_FORWARDING -o activate)"
motion_stream_hostname="$($CONFIGHANDLER -s APACHE_MOTION_STREAM_FORWARDING -o stream_hostname)"
motion_stream_port="$($CONFIGHANDLER -s APACHE_MOTION_STREAM_FORWARDING -o stream_port)"
motion_proxy_point="$($CONFIGHANDLER -s APACHE_MOTION_STREAM_FORWARDING -o proxy_point)"

apache_html_folder_link_to="$($CONFIGHANDLER -s APACHE -o html_folder_link_to)"
apache_conf="/etc/apache2/apache2.conf"

source "${MYDIR}/../message.bash"
_msg_title="motion stream forwarding SETUP"

function set_apache_conf_proxy() {
    local is_set_proxy_forwarding="$(cat $apache_conf | grep -v grep | grep ${motion_proxy_point})"
    local text=""
    if [  "$is_set_proxy_forwarding" == "" ]
    then
        _msg_ "Set $apache_conf for motion stream forwarding"
        text="\n# external motion camera stream forwarding under apache\n"
        text+="ProxyPass ${motion_proxy_point} http://${motion_stream_hostname}:${motion_stream_port}\n"
        text+="ProxyPassReverse ${motion_proxy_point} http://${motion_stream_hostname}:${motion_stream_port}\n"
        sudo echo -e "$text" >> "$apache_conf"
        _msg_ "Restart apache: sudo systemctl restart apache2"
        sudo systemctl restart apache2
    else
        _msg_ "Already set: $apache_conf for motion stream forwarding"
    fi
}

if [[ "$motion_action_stream_forward" == "True" ]] || [[ "$motion_action_stream_forward" == "true" ]]
then
    _msg_ "Motion remote stream forwarding IS required" 
    set_apache_conf_proxy
else
    _msg_ "Motion remote stream forwarding IS NOT required"
fi
