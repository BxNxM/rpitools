#!/bin/bash

arg_len="$#"
arg="$1"
force="False"

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.apache_set_done"
source "${MYDIR_}/../../../prepare/colors.bash"

html_folder_path="/var/www/html/"
webshared_root_folder_name="cloud"
apache_webshared_root_folder="${html_folder_path}/${webshared_root_folder_name}"
template_folder_path="${MYDIR_}/template/"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
html_folder_link_to="$($confighandler -s APACHE -o html_folder_link_to)"
html_shared_default_user="$($confighandler -s APACHE -o http_user)"
html_shared_default_user_password="$($confighandler -s APACHE -o http_passwd)"
html_shared_folder_private="${apache_webshared_root_folder}/private_cloud"
html_shared_folder_public="${apache_webshared_root_folder}/public_cloud"
transmission_downloads_path="$($confighandler -s TRANSMISSION -o download_path)"
motion_video_stream_is_activated="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o activate)"
motion_video_stream_proxy_point="$($confighandler -s APACHE_MOTION_STREAM_FORWARDING -o proxy_point)"
apache2_conf_path="/etc/apache2/apache2.conf"


# SET APACHE ENVIRONMENT PATH FILE FOROTHER SOURCE FILES LIKE MOTION...
export_env="export APACHE_WEBSHARED_ROOT_FOLDER=${apache_webshared_root_folder}\n"
export_env+="export APACHE_HTML_ROOT_FOLDER=${html_folder_path}\n"
export_env+="export APACHE_PRIVATE_SHARED_FOLDER=${html_shared_folder_private}\n"
export_env+="export APACHE_PUBLIC_SHARED_FOLDER=${html_shared_folder_public}"
echo -e "${export_env}" > ${MYDIR_}/apache.env

source "${MYDIR_}/../message.bash"
_msg_title="APACHE SETUP"

if [ "$arg_len" -eq 1 ]
then
    if [ "$arg" == "-f" ] || [ "$arg" == "-force" ]
    then
        _msg_ "FORCE MODE ON - REWRITE actual /var/www/html folder"
        force="True"
    fi
fi

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

function copy_template_under_apache_html_folder() {

    _msg_ "CLEAN: ${html_folder_path}"
    sudo rm -rf ${html_folder_path}*

    _msg_ "COPY: ${template_folder_path}* ${html_folder_path}"
    sudo cp -rp ${template_folder_path}* "${html_folder_path}"

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
    is_edited="$(grep -i '<Directory /var/www/html>' $apache2_conf_path)"
    if [ "$?" -ne 0 ]
    then
        _msg_ "Configure $apache2_conf_path for custom rpitools shaerd folder."
        apache2_config='# SHARED FODER FOR RPITOOLS APACHE\n'
        apache2_config+='<Directory /var/www/html>\n'
        apache2_config+='         Options Indexes Includes FollowSymLinks MultiViews\n'
        apache2_config+='         # AllowOverride AuthConfig\n'
        apache2_config+='         AllowOverride All\n'
        apache2_config+='         Order allow,deny\n'
        apache2_config+='         Allow from all\n'
        apache2_config+='</Directory>\n'
        sudo chmod go+rw "$apache2_conf_path"
        echo -e "$apache2_config"
        echo -e "$apache2_config" >> "$apache2_conf_path"
        sudo chmod g-rw "$apache2_conf_path"

        _msg_ "Reload apache2: sudo /etc/init.d/apache2 force-reload"
        sudo /etc/init.d/apache2 force-reload
    else
        _msg_ "$apache2_conf_path already configured with <Directory /var/www/html>"
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
        htpasswd -cb /home/$USER/.secure/apasswords "$html_shared_default_user" "$html_shared_default_user_password"
    else
        _msg_ "/home/$USER/.secure/apasswords already exists"
    fi

    if [ ! -e "${html_shared_folder_private}/.htaccess" ]
    then
        _msg_ "Create ${html_shared_folder_private}/.htaccess"
        htaccess_config="AuthType Basic\n"
        htaccess_config+="AuthName \"Restricted Access\"\n"
        htaccess_config+="AuthUserFile /home/$USER/.secure/apasswords\n"
        htaccess_config+="Require user $html_shared_default_user\n"
        (sudo touch "${html_shared_folder_private}/.htaccess")
        sudo chmod go+rw "${html_shared_folder_private}/.htaccess"
        echo -e "$htaccess_config"
        echo -e "$htaccess_config" >> "${html_shared_folder_private}/.htaccess"
        sudo chmod o-w "${html_shared_folder_private}/.htaccess"
    else
        _msg_ "${html_shared_folder_private}/.htaccess already exists"
    fi
}

function create_cloud_structure() {
    if [ ! -e "${html_shared_folder_private}" ]
    then
        _msg_ "Create ${html_shared_folder_private}"
        sudo mkdir -p "${html_shared_folder_private}"
    fi
    if [ ! -e "${html_shared_folder_public}" ]
    then
        _msg_ "Create ${html_shared_folder_public}"
        sudo mkdir -p "${html_shared_folder_public}"
    fi
}

function link_transmission_downloads_folder() {
    if [ ! -e "${html_shared_folder_private}/downloads" ]
    then
        _msg_ "TRANSMISSION DOWNLOADS LINK: $transmission_downloads_path -> ${html_shared_folder_private}/downloads"
        sudo ln -s "$transmission_downloads_path" "${html_shared_folder_private}/downloads"
    else
        _msg_ "TRANSMISSION DOWNLOADS LINK: $transmission_downloads_path -> ${html_shared_folder_private}/downloads already exists"
    fi
}

function set_embedded_transmission_access() {
    is_edited="$(sudo cat $apache2_conf_path | grep 'ProxyPass /transmission')"
    if [ "$is_edited" == "" ]
    then
        _msg_ "Configure, for proxy redirect (transmission) run command:\na2enmod proxy\na2enmod proxy_http"
        sudo a2enmod proxy
        if [ "$?" -ne 0 ]; then echo -e "install failed"; exit 1; fi
        sudo a2enmod proxy_http
        if [ "$?" -ne 0 ]; then echo -e "install failed"; exit 1; fi

        _msg_ "Configure $apache2_conf_path for embedded transmission access."
        apache2_config='# ENABLE APACHE EMBEDDED TRANSMISSION ACCESS\n'
        apache2_config+='ProxyRequests Off\n'
        apache2_config+='<Proxy *>\n'
        apache2_config+='Order Allow,Deny\n'
        apache2_config+='         Allow from all\n'
        apache2_config+='</Proxy>\n'
        apache2_config+='ProxyPass /transmission http://localhost:9091/transmission\n'
        apache2_config+='ProxyPassReverse /transmission http://localhost:9091/transmission\n'
        sudo chmod go+rw "$apache2_conf_path"
        echo -e "$apache2_config"
        echo -e "$apache2_config" >> "$apache2_conf_path"
        sudo chmod g-rw "$apache2_conf_path"

        _msg_ "Reload apache2: sudo /etc/init.d/apache2 force-reload"
        sudo /etc/init.d/apache2 force-reload
    else
        _msg_ "$apache2_conf_path already configured ProxyPass /transmission"
    fi
}

function motion_stream_forwarding_apache_link_icon() {
    local index_html_motion_icon_placeholder="    <!--MOTION_STREAM_ICON_PLACEHOLDER-->"
    local http_cmd="    <a href=\"$motion_video_stream_proxy_point\"><img align=\"right\" src=\"media/webcam.png\" style=\"width:50px;height:auto\"></a>"
    local index_html_to_edit_path="${html_folder_path}/index.html"
    local is_activated="$motion_video_stream_is_activated"

    if [[ "$is_activated" == "true" ]] || [[ "$is_activated" == "True" ]]
    then
        _msg_ "Set motion stream forwarding icon link required [ $is_activated ]"
        change_line "$index_html_motion_icon_placeholder" "$http_cmd" "$index_html_to_edit_path"
    else
        _msg_ "Set motion stream forwarding icon link NOT required [ $is_activated ]"
        change_line "media\/webcam.png" "$index_html_motion_icon_placeholder" "$index_html_to_edit_path"
    fi
}

function sites_enabled_000-defaultconf_patch() {
    # https://www.thegeekstuff.com/2014/12/patch-command-examples/
    local apache2_sites_available_000_default_conf_path="/etc/apache2/sites-available/000-default.conf"
    local patch_file_path="${MYDIR_}/patches/000-default_patch.conf"

    # CREATE PATH FILE
    #diff -u ORIGINAL FINAL > PATCH

    (grep "ErrorDocument 404 /error.html" -rnwi "$apache2_sites_available_000_default_conf_path" > /dev/null)
    if [ "$?" -ne 0 ]
    then
        _msg_ "APPLY PATH: sudo patch $apache2_sites_available_000_default_conf_path $patch_file_path"
        # sudo patch OFFICIAL PATCH
        sudo patch "$apache2_sites_available_000_default_conf_path" "$patch_file_path"

        _msg_ "PATCH DONE [$?] restart apache2 service"
        sudo systemctl restart apache2
    else
        _msg_ "$apache2_sites_available_000_default_conf_path already patched"
    fi
}

function restore_backup_cloud_storage_content() {
    local mode="$1"
    local obsolete_webshared_folder_path="${html_folder_path}/webshared/"
    local html_shared_folder_private_path="${html_shared_folder_private}/"
    local html_shared_folder_public_path="${html_shared_folder_public}/"
    local tmp_workspace="/tmp/apache_migration/"

    if [ "$mode" == "backup" ]
    then
        _msg_ "Create backup before override $html_folder_path to $tmp_workspace"
        # create tmp workspace
        if [ -e "${tmp_workspace}" ]
        then
            sudo rm -rf "${tmp_workspace}"
        fi
        sudo mkdir -p "$tmp_workspace"

        if [ -e "$obsolete_webshared_folder_path" ]
        then
            _msg_ "\tCopy: $obsolete_webshared_folder_path -> $tmp_workspace"
            sudo cp -rp "$obsolete_webshared_folder_path" "$tmp_workspace"
        fi
        if [ -e "$html_shared_folder_private_path" ]
        then
            _msg_ "\tCopy: $html_shared_folder_private_path -> $tmp_workspace"
            sudo cp -rp "$html_shared_folder_private_path" "$tmp_workspace"
        fi
        if [ -e "$html_shared_folder_public_path" ]
        then
            _msg_ "\tCopy: $html_shared_folder_public_path -> $tmp_workspace"
            sudo cp -rp "$html_shared_folder_public_path" "$tmp_workspace"
        fi
    elif [ "$mode" == "restore" ]
    then
        _msg_ "Restore from $tmp_workspace to  $html_folder_path"
        if [ -e "${tmp_workspace}webshared" ]
        then
            _msg_ "\tCopy: ${tmp_workspace}webshared -> $html_shared_folder_private_path"
            sudo cp -rp ${tmp_workspace}webshared/* "$html_shared_folder_private_path"
        fi
        local tmp_private_path="${tmp_workspace}/private_cloud"
        if [ -e "$tmp_private_path" ]
        then
            _msg_ "\tCopy: $tmp_private_path -> ${html_shared_folder_private_path}"
            sudo cp -rp ${tmp_private_path}/* "${html_shared_folder_private_path}"
        fi
        local tmp_public_path="${tmp_workspace}/public_cloud"
        if [ -e "$tmp_public_path" ]
        then
            _msg_ "\tCopy: $tmp_public_path -> ${html_shared_folder_public_path}"
            sudo cp -rp ${tmp_public_path}/* "${html_shared_folder_public_path}"
        fi
        sudo rm -rf "${tmp_workspace}"
    else
        _msg_ "Unknown mode: $mode"
    fi


}

function generate_project_structure() {
    folder="/home/$USER/rpitools"; tree "$folder" -T "RPITOOLS FILE STRUCURE" -H rpitools -C > "${MYDIR_}/template/htmls/$(basename ${folder})_file_structure.html"; sed -i 's|href=".*"||g' "${MYDIR_}/template/htmls/$(basename ${folder})_file_structure.html"
}
generate_project_structure

link_html_folder_to_requested_path
if [ ! -e "$CACHE_PATH_is_set" ] || [ "$force" == "True" ]
then
    restore_backup_cloud_storage_content "backup"
    copy_template_under_apache_html_folder
    create_cloud_structure
    restore_backup_cloud_storage_content "restore"

    echo -e "$(date)" > "$CACHE_PATH_is_set"
    link_transmission_downloads_folder

    sites_enabled_000-defaultconf_patch
else
    _msg_ "HTML template copy already done: ${CACHE_PATH_is_set} exists."
fi
set_shared_folder_password_protected
set_embedded_transmission_access

motion_stream_forwarding_apache_link_icon

. "${MYDIR_}/setup_h5ai.bash"

. "$MYDIR_/glances/setup_glances_system_monitor.bash"
