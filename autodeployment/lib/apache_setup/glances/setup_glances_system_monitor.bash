#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.apache_glance_set_done"
source "${MYDIR_}/../../../../prepare/colors.bash"
source "${MYDIR_}/../apache.env"
html_folder_path="$APACHE_HTML_ROOT_FOLDER"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
is_install_glances="$($confighandler -s APACHE -o glances_service)"
glances_username="$($confighandler -s APACHE -o glances_username)"
glances_password="$($confighandler -s APACHE -o glances_password)"
glanes_icon_status="$($confighandler -s APACHE -o glances_icon)"
# parameters
glance_stream_hostname="glances"
glance_stream_port="61208"
apache2_conf_path="/etc/apache2/apache2.conf"

source "${MYDIR_}/../../message.bash"
_msg_title="Setup glances system monitor"

function change_line() {
    local from="$1"
    local to="$2"
    local where="$3"
    if [ ! -z "$from" ]
    then
        _msg_ "sudo cat $where | grep -v grep | grep $to\nis_set: $is_set"
        is_set="$(sudo cat "$where" | grep "$to")"
        _msg_ "$is_set"
        if [ "$is_set" == "" ]
        then
            _msg_ "${GREEN}Set parameter (full line): $to  (from: $from) ${NC}"
            sudo sed -i '/'"${from}"'/c\'"${to}"'' "$where"
        else
            _msg_ "${GREEN}Custom config line $to already set in $where ${NC}"
        fi
    fi
}

function install_glances() {
    curl -L https://bit.ly/glances | /bin/bash
    if [ "$?" -eq 0 ]
    then
        sudo bash -c "sudo ufw allow $glance_stream_port"
        set_glances_username_and_password "$glances_username" "$glances_password"
        echo -e "$(date)" > ${CACHE_PATH_is_set}
    fi
}

function set_glances_username_and_password() {
    local username="$1"
    local password="$2"
    _msg_ "Set glances username $username with ***** password"
    /usr/bin/expect -c 'spawn /usr/bin/python /usr/local/bin/glances --webserver --disable-process --process-short-name --hide-kernel-threads --port 61208 --percpu --disable-irix -B 0.0.0.0 --username --password; expect "Define the Glances webserver username:"; send -- "'"$username"'\r"; expect "Define the Glances webserver password*"; send -- "'"$password"'\r"; expect "Password (confirm):"; send -- "'"$password"'\r"; expect "Do you want to save the password?*"; send -- "Yes\r"; expect eof'
}

function glance_subpage_forwarding_apache_link_icon() {
    local glance_page_proxy_point="/${glance_stream_hostname}/"
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

    glanes_proxy_point="/$glance_stream_hostname"
    is_edited="$(sudo cat $apache2_conf_path | grep 'ProxyPass '"$glanes_proxy_point"'')"
    if [ "$is_edited" == "" ]
    then
        _msg_ "Configure, for proxy redirect ($glance_stream_hostname) run command:\na2enmod proxy\na2enmod proxy_http"
        sudo a2enmod proxy
        if [ "$?" -ne 0 ]; then echo -e "install failed"; exit 1; fi
        sudo a2enmod proxy_http
        if [ "$?" -ne 0 ]; then echo -e "install failed"; exit 1; fi

        _msg_ "Configure $apache2_conf_path for embedded $glance_stream_hostname access."
        glances_config='# ENABLE APACHE EMBEDDED '"$glance_stream_hostname"' ACCESS\n'
        glances_config+='ProxyRequests Off\n'
        glances_config+='<Proxy *>\n'
        glances_config+='Order Allow,Deny\n'
        glances_config+='         Allow from all\n'
        glances_config+='</Proxy>\n'
        glances_config+='ProxyPass '"$glanes_proxy_point"' http://localhost:'"${glance_stream_port}"'\n'
        glances_config+='ProxyPassReverse '"$glanes_proxy_point"' http://localhost:'"${glance_stream_port}"'\n'
        sudo chmod go+rw "$apache2_conf_path"
        echo -e "$glances_config"
        echo -e "$glances_config" >> "$apache2_conf_path"
        sudo chmod g-rw "$apache2_conf_path"

        _msg_ "Reload apache2: sudo /etc/init.d/apache2 force-reload"
        sudo a2enmod rewrite && sudo /etc/init.d/apache2 restart
        sudo /etc/init.d/apache2 force-reload
    else
        _msg_ "$apache2_conf_path already configured ProxyPass ${glanes_proxy_point}"
    fi
}

# MAIN
echo -e "GLANES OFFICIAL WEBSITE: https://github.com/nicolargo/glances" | /usr/games/lolcat
if [ "$is_install_glances" == "True" ] || [ "$is_install_glances" == "true" ]
then
    echo -e "Default port: $glance_stream_port" | /usr/games/lolcat
    if [ ! -e "$CACHE_PATH_is_set" ]
    then
        _msg_ "Install glances..."
        install_glances
        set_apache_conf_proxy
    else
        _msg_ "Glance was already installed. $CACHE_PATH_is_set exists."
    fi

    glance_subpage_forwarding_apache_link_icon
fi

"${MYDIR_}"/systemd_setup/set_service.bash
