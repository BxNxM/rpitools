#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
motion_action_stream_forward="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o activate)"
motion_stream_hostname="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o stream_hostname)"
motion_stream_port="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o stream_port)"
motion_proxy_point="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o proxy_point)"
motion_apache_subpage_name="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o apache_subpage_name).html"

apache_html_folder_link_to="$($confighandler -s APACHE -o html_folder_link_to)"
apache_conf="/etc/apache2/apache2.conf"

_msg_title="motion stream forwarding SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${GREEN}[ $_msg_title ]${NC} - $msg"
}

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

function generate_subpage_for_streaming() {
    _msg_ "Set (override) ${apache_html_folder_link_to}/$motion_apache_subpage_name based on rpi_config"
    local text=""
    text+="<html>\n"
    text+="<head>\n"
    text+="</head>\n"
    text+="<body>\n"
    text+="    <br>\n"
    text+="        Click for the stream:<br>\n"
    text+="        <br>\n"
    text+="        <a href=\"${motion_proxy_point}\">STREAM</a>\n"
    text+="    </p>\n"
    text+="    </tr>\n"
    text+="    </table>\n"
    text+="</body>\n"
    text+="</html>\n"
    sudo echo -e "$text" > "${apache_html_folder_link_to}/$motion_apache_subpage_name" 
    _msg_ "Restart apache: sudo systemctl restart apache2"
    sudo systemctl restart apache2
}

if [[ "$motion_action_stream_forward" == "True" ]] || [[ "$motion_action_stream_forward" == "true" ]]
then
    _msg_ "Motion remote stream forwarding IS required" 
    set_apache_conf_proxy
    generate_subpage_for_streaming
else
    _msg_ "Motion remote stream forwarding IS NOT required"
fi
