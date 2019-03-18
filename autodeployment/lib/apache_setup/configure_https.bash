#!/bin/bash

#https://variax.wordpress.com/2017/03/18/adding-https-to-the-raspberry-pi-apache-web-server/comment-page-1/?fbclid=IwAR0_gTkFAaFkGswBNg_4NIaopA5Ujb9wHdp6GS4yqNwiT7eCvbtwo7fcj6o

ARGLIST=($@)
MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cert_dir_path="/etc/ssl/localcerts"
cert_pem_path="${cert_dir_path}/apache.pem"
cert_key_path="${cert_dir_path}/apache.key"
cert_expiry_days=365
sites_available_path="/etc/apache2/sites-available"

source "${MYDIR_}/../message.bash"
_msg_title="APACHE SSL SETUP"

function download_dependences() {
    _msg_ "Download openssl"
    sudo apt-get install openssl
}

function create_certificate() {
    _msg_ "Create certificates dir: $cert_dir_path"
    sudo mkdir -p "$cert_dir_path"

    _msg_ "Create SSL cretificate under: $cert_dir_path ..."
    sudo openssl req -new -x509 -days "$cert_expiry_days" -nodes -out "$cert_pem_path" -keyout "$cert_key_path"

    _msg_ "Certificates $cert_dir_path:"
    certs=($(ls -1 "$cert_dir_path"))
    if [ "${#certs[@]}" -gt 2 ] || [ "${#certs[@]}" -eq 2 ]
    then
        _msg_ "\tOK"
        echo -e "${certs[*]}"

        _msg_ "\tChmod certificates: 600"
        sudo chmod 600 /etc/ssl/localcerts/apache*
        # in case of fail: sudo a2ensite default-ssl
    else
        echo -e "\tFAIL, $cert_dir_path is empty!"
    fi
}

function configure_certificate() {
        pushd "$sites_available_path"
        local ssh_default_conf_name="default-ssl.conf"
        if [ -f "$ssh_default_conf_name" ]
        then
            _msg_ "Copy $ssh_default_conf_name to ${HOSTNAME}.conf"
            sudo cp -f "$ssh_default_conf_name" "${HOSTNAME}.conf"
        else
            _msg_ "$sites_available_path/$ssh_default_conf_name not exists!"
        fi
        # popd
}

function enable_https_port(){
    local open_posts="$(sudo ufw status)"
    if [[ "$open_posts" != *"443"* ]]
    then
        sudo ufw allow 443
    fi
}

if [ ! -e "$cert_key_path" ] || [ "${ARGLIST[0]}" == "-r" ]
then
    if [ "${ARGLIST[0]}" == "-r" ]
    then
        _msg_ "regenerate certificate"
    else
        download_dependences
    fi
    create_certificate
    enable_https_port
else
    _msg_ "Openssl is already downloaded, and certificate was successfully generated"
    _msg_ "To regenerate certificate use -r (regenerate) command line argument"
fi

configure_certificate

