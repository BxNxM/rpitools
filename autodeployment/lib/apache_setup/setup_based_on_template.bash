#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACHE_PATH_is_set="/home/$USER/rpitools/cache/.apache_set_done"
source "${MYDIR_}/../../../prepare/colors.bash"

html_folder_path="/var/www/html/"
template_folder_path="${MYDIR_}/template/"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
html_folder_link_to="$($confighandler -s APACHE -o html_folder_link_to)"

_msg_title="APACHE SETUP"
function _msg_() {
    local msg="$1"
    echo -e "${BLUE}[ $_msg_title ]${NC} - $msg"
}

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

link_html_folder_to_requested_path
if [ ! -e "$CACHE_PATH_is_set" ]
then
    copy_template_under_apache_html_folder
    echo -e "$(date)" > "$CACHE_PATH_is_set"
else
    _msg_ "HTML template copy already done: ${CACHE_PATH_is_set} exists."
fi
