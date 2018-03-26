#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dropbox_uploader="${MYDIR}/Dropbox-Uploader/dropbox_uploader.sh"
local_cache_folder="${MYDIR}/local_cache/"
server_extension="_extIP"
local_requests_cache="${MYDIR}/local_cache/requests_cache/"

if [ ! -d "$local_requests_cache" ]
then
    mkdir -p "$local_requests_cache"
fi

function get_server_info() {
    local required_server_tag="$1"
    if [ -z "$required_server_tag" ]
    then
        echo -e "input not found <tag>"
    fi

    servers=$($dropbox_uploader list halpage/servers/)
    local server_full_tag="${required_server_tag}${server_extension}"
    if [[ "$servers" == *"${server_full_tag}"* ]]
    then
        echo -e "${server_full_tag} exists"
        _download_server_info_and_parse "halpage/servers/${server_full_tag}"
    else
        echo -e "${server_full_tag} not exists"
    fi
}

function _download_server_info_and_parse() {
    local server_info_file_name="$1"
    local server_basename="$(basename $server_info_file_name)"
    echo -e "Dropbox-Uploader/dropbox_uploader.sh download $server_info_file_name ${local_requests_cache}${server_basename}"
    local get_server_info_file=$($dropbox_uploader download "$server_info_file_name" "${local_requests_cache}${server_basename}")
    echo -e "$get_server_info_file"
    info_txt=$(cat ${local_requests_cache}${server_basename})
    echo -e "$info_txt"
}

function list_servers() {
    servers=$($dropbox_uploader list halpage/servers/)
    echo -e "$servers"
}

list_servers
get_server_info "portablepi"
#get_server_info "asd"


