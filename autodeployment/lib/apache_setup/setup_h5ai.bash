#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../../prepare/colors.bash"

html_folder_path="/var/www/html/"
webshared_root_folder_name="cloud"
apache_webshared_root_folder="${html_folder_path}/${webshared_root_folder_name}"
html_shared_folder_private="${apache_webshared_root_folder}/private_cloud"
html_shared_folder_public="${apache_webshared_root_folder}/public_cloud"
h5ai_folder_name="_h5ai"
apache2_conf_path="/etc/apache2/apache2.conf"
restart_required=0

source "${MYDIR_}/../message.bash"
_msg_title="h5ai SETUP"

function download_and_prepare_h5ai() {
    pushd "$MYDIR_"

    if [ ! -d "$h5ai_folder_name" ]
    then
        _msg_ "download"
        wget https://release.larsjung.de/h5ai/h5ai-0.29.0.zip
        _msg_ "unzip"
        unzip h5ai-0.29.0.zip

        restart_required=$((restart_required+1))
    else
        _msg_ "already downloaded"
    fi

    _msg_ "set cache permissions: _h5ai/private/cache/ and _h5ai/public/cache/"
    sudo chmod o+w _h5ai/private/cache/
    sudo chmod o+w _h5ai/public/cache/

    popd
}

function copy_h5ai_to() {
    local to="$1"
    if [ ! -d "${to}/${h5ai_folder_name}" ]
    then
        _msg_ "copy ${MYDIR_}/${h5ai_folder_name} to ${to}/${h5ai_folder_name} "
        sudo cp -rp "${MYDIR_}/${h5ai_folder_name}" "${to}/${h5ai_folder_name}"
        restart_required=$((restart_required+1))
    else
        _msg_ " ${to}/${h5ai_folder_name} already exists."
    fi
}

function generate_htaccess() {
    local h5ai_path="$1"
    local htaccess_content="DirectoryIndex  index.html  index.php /${h5ai_path}/_h5ai/public/index.php"
    local full_htaccess_path="${html_folder_path}/${h5ai_path}/.htaccess"
    grep -i "${htaccess_content}" "$full_htaccess_path"
    if [ "$?" -ne 0 ]
    then
        _msg_ "add $htaccess_content to .htaccess"
        sudo bash -c "echo -e ${htaccess_content} >> ${full_htaccess_path}"
        restart_required=$((restart_required+1))
    else
        _msg_ "$htaccess_content already added."
    fi
}

function override_apache2conf_workaround() {
    (grep "#AllowOverride AuthConfig" "$apache2_conf_path")
    if [ "$?" -ne 0 ]
    then
	_msg_ "hack apache2.conf: AllowOverride AuthConfig --> #AllowOverride AuthConfig"
	sudo bash -c "sed -i 's|AllowOverride AuthConfig|#AllowOverride AuthConfig|g' $apache2_conf_path"
        restart_required=$((restart_required+1))
    fi

    (grep -zl '#AllowOverride AuthConfig.*AllowOverride All' "$apache2_conf_path")
    if [ "$?" -ne 0 ]
    then
        _msg_ "hack apache2.conf: add AllowOverride All"
        sudo bash -c "sed -i 's|#AllowOverride AuthConfig|#AllowOverride AuthConfig\n         AllowOverride All|g' $apache2_conf_path"
        restart_required=$((restart_required+1))
    fi

}

function restart_if_required() {
    if [ "$restart_required" -gt 0 ]
    then
        _msg_ "restart apache2"
        sudo systemctl restart apache2
    fi
}

_msg_ "$(date)"
override_apache2conf_workaround

download_and_prepare_h5ai
copy_h5ai_to "$html_shared_folder_private"
copy_h5ai_to "$html_shared_folder_public"
generate_htaccess "${webshared_root_folder_name}/private_cloud/"
generate_htaccess "${webshared_root_folder_name}/public_cloud/"

restart_if_required
