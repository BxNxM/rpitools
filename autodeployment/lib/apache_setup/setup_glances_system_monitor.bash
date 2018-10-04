#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.apache_glance_set_done"
source "${MYDIR_}/../../../prepare/colors.bash"
source "${MYDIR_}/apache.env"
html_folder_path="$APACHE_HTML_ROOT_FOLDER"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
is_install_glances="$($confighandler -s APACHE -o install_glances)"
glanes_icon_status="$($confighandler -s APACHE -o glances_icon)"
glance_stream_hostname="glacepage"
glance_stream_port="61208"

source "${MYDIR_}/../message.bash"
_msg_title="Setup glances system monitor"

function install_glances() {
    curl -L https://bit.ly/glances | /bin/bash
    if [ "$?" -eq 0 ]
    then
        echo -e "$(date)" > ${CACHE_PATH_is_set}
    fi
}

function glance_subpage_forwarding_apache_link_icon() {
    local index_html_glances_icon_placeholder="    <!--GLANCE_SUBPAGE_ICON_PLACEHOLDER-->"
    local http_cmd="    <a href=\"$glance_page_proxy_point\"><img align=\"right\" src=\"media/glances_icn.png\" style=\"width:50px;height:auto\"></a>"
    local index_html_to_edit_path="${html_folder_path}/index.html"
    local is_activated="$glanes_icon_status"

    if [[ "$is_activated" == "true" ]] || [[ "$is_activated" == "True" ]]
    then
        _msg_ "Set glanes icon on website main page [ $is_activated ]"
        change_line "$index_html_glances_icon_placeholder" "$http_cmd" "$index_html_to_edit_path"
    else
        _msg_ "Unset glanes icon on website main page [ $is_activated ]"
        change_line "media\/glances_icn.png" "$index_html_glances_icon_placeholder" "$index_html_to_edit_path"
    fi
}

function set_apache_conf_proxy() {
    local is_set_proxy_forwarding="$(cat $apache_conf | grep -v grep | grep ${motion_proxy_point})"
    local text=""
    if [  "$is_set_proxy_forwarding" == "" ]
    then
        _msg_ "Set $apache_conf for motion stream forwarding"
        text="\n# external motion camera stream forwarding under apache\n"
        text+="ProxyPass ${motion_proxy_point} http://${glance_stream_hostname}:${glance_stream_port}\n"
        text+="ProxyPassReverse ${motion_proxy_point} http://${glance_stream_hostname}:${glance_stream_port}\n"
        sudo echo -e "$text" >> "$apache_conf"
        _msg_ "Restart apache: sudo systemctl restart apache2"
        sudo systemctl restart apache2
    else
        _msg_ "Already set: $apache_conf for motion stream forwarding"
    fi
}

if [ "$is_install_glances" == "True" ] || [ "$is_install_glances" == "true" ]
then
    if [ ! -e "$CACHE_PATH_is_set" ]
    then
        _msg_ "Install glances..."
        install_glances
        set_apache_conf_proxy
        # set service ....
    else
        _msg_ "Glance was already installed. $CACHE_PATH_is_set exists."
    fi

    glance_subpage_forwarding_apache_link_icon
fi
