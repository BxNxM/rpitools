#!/bin/bash

arg_len="$#"
arg="$1"
force="False"

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.apache_set_done"
source "${MYDIR_}/../../../prepare/colors.bash"

html_folder_path="/var/www/html/"
template_folder_path="${MYDIR_}/template/"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
html_folder_link_to="$($confighandler -s APACHE -o html_folder_link_to)"
html_shared_default_user="$($confighandler -s APACHE -o http_user)"
html_webshared_folder_name="$($confighandler -s APACHE -o webshared_folder_name)"
html_shared_folder="${html_folder_path}/${html_webshared_folder_name}"

_msg_title="APACHE SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
}

if [ "$arg_len" -eq 1 ]
then
    if [ "$arg" == "-f" ] || [ "$arg" == "-force" ]
    then
        _msg_ "FORCE MODE ON - REWRITE actual /car/www/html folder"
        force="True"
    fi
fi

function copy_template_under_apache_html_folder() {

    _msg_ "CLEAN: ${html_folder_path}"
    sudo rm -rf ${html_folder_path}*

    _msg_ "COPY: ${template_folder_path}* ${html_folder_path}"
    sudo cp -r ${template_folder_path}* "${html_folder_path}"

    _msg_ "YOUR ${html_folder_path} CONTENT:"
    ls -lrth "${html_folder_path}"
}

function link_html_folder_to_requested_path() {
    if [ ! -e "${html_folder_link_to}" ]
    then
        _msg_ "LINK HTML FOLDER: ln -s ${html_folder_path} ${html_folder_link_to}"
        ln -s "${html_folder_path}" "${html_folder_link_to}"
    else
        _msg_ "HTML LINK ALREADY DONE: ${html_folder_link_to}"
    fi
}

function set_shared_folder_password_protected() {
    is_edited="$(sudo cat /etc/apache2/apache2.conf | grep '<Directory /var/www/html>')"
    if [ "$is_edited" == "" ]
    then
        _msg_ "Configure /etc/apache2/apache2.conf for custom rpitools shaerd folder."
        apache2_config='# SHARED FODER FOR RPITOOLS APACHE\n'
        apache2_config+='<Directory /var/www/html>\n'
        apache2_config+='         Options Indexes Includes FollowSymLinks MultiViews\n'
        apache2_config+='         AllowOverride AuthConfig\n'
        apache2_config+='         Order allow,deny\n'
        apache2_config+='         Allow from all\n'
        apache2_config+='</Directory>\n'
        sudo chmod go+rw /etc/apache2/apache2.conf
        echo -e "$apache2_config"
        echo -e "$apache2_config" >> /etc/apache2/apache2.conf
        sudo chmod g-rw /etc/apache2/apache2.conf

        _msg_ "Reload apache2: sudo /etc/init.d/apache2 force-reload"
        sudo /etc/init.d/apache2 force-reload
    else
        _msg_ "/etc/apache2/apache2.conf already configured with <Directory /var/www/html>"
    fi

    if [ ! -e "/home/$USER/.secure/" ]
    then
        _msg_ "Create password folder: mkdir -p /home/$USER/.secure/"
        mkdir -p /home/$USER/.secure/
    else
        _msg_ "/home/$USER/.secure/ already exists"
    fi

    if [ ! -e "/home/$USER/.secure/apasswords" ]
    then
        _msg_ "Create password for user: htpasswd -c /home/$USER/.secure/apasswords $html_shared_default_user"
        htpasswd -c /home/$USER/.secure/apasswords $html_shared_default_user
    else
        _msg_ "/home/$USER/.secure/apasswords already exists"
    fi

    if [ ! -e "${html_shared_folder}/.htaccess" ]
    then
        _msg_ "Create ${html_shared_folder}/.htaccess"
        htaccess_config="AuthType Basic\n"
        htaccess_config+="AuthName \"Restricted Access\"\n"
        htaccess_config+="AuthUserFile /home/$USER/.secure/apasswords\n"
        htaccess_config+="Require user $html_shared_default_user\n"
        (sudo touch "${html_shared_folder}/.htaccess")
        sudo chmod go+rw "${html_shared_folder}/.htaccess"
        echo -e "$htaccess_config"
        echo -e "$htaccess_config" >> "${html_shared_folder}/.htaccess"
        sudo chmod o-w "${html_shared_folder}/.htaccess"
    else
        _msg_ "${html_shared_folder}/.htaccess already exists"
    fi
}

link_html_folder_to_requested_path
if [ ! -e "$CACHE_PATH_is_set" ] || [ "$force" == "True" ]
then
    copy_template_under_apache_html_folder
    echo -e "$(date)" > "$CACHE_PATH_is_set"
else
    _msg_ "HTML template copy already done: ${CACHE_PATH_is_set} exists."
fi
set_shared_folder_password_protected
