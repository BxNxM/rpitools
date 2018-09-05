#!/bin/bash

#========================= handle parameters ==========================
args_len="$#"
arg_list=( "$@" )
if [ "$args_len" -ne 0 ]
then
    #echo -e "args: ${arg_list[@]}"
    for ((k=0; k<"${#arg_list[@]}"; k++))
    do
        arg="${arg_list[$k]}"
        #echo -e "$arg"
        if [ "$arg" == "--name" ] || [ "$arg" == "-n" ]
        then
            n=$((k+1))
            server_remote_name="${arg_list[$n]}"
        fi
        if [ "$arg" == "--ip" ] || [ "$arg" == "-i" ]
        then
            ip_switch=1
        fi
        if [ "$arg" == "--port" ] || [ "$arg" == "-p" ]
        then
            port_switch=1
        fi
        if [ "$arg" == "--list" ] || [ "$arg" == "-l" ]
        then
            list_switch=1
        fi
        if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
        then
            echo -e "--name\t-\tadd server name"
            echo -e "--ip\t-\tfilter for IP address"
            echo -e "--port\t-\tfilder for PORT number"
            echo -e "--list\t-\tlist your servers"
        fi
    done
else
    echo -e "USE: --help"
fi

#=============================================================================
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dropbox_uploader="${MYDIR}/Dropbox-Uploader/dropbox_uploader.sh"
local_cache_folder="${MYDIR}/local_cache/"
#server_extension="_extIP"
server_extension=""
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
        #echo -e "${server_full_tag} exists"
        access_info=$(_download_server_info_and_parse "halpage/servers/${server_full_tag}")
        access_info_list=( $access_info )
        access_ip_port=("${access_info_list[-2]}" "${access_info_list[-1]}")
        #echo -e "|${access_info_list[@]}|"
        #echo -e "${access_ip_port[@]}"
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

    if [ -e "${local_requests_cache}${server_basename}" ]
    then
        info_txt="$(cat ${local_requests_cache}${server_basename})"
    else
        info_txt="undef"
    fi
    echo -e "$info_txt"
}

function list_servers() {
    servers=$($dropbox_uploader list halpage/servers/)
    echo -e "$servers"
}

########################## MAIN #######################
if [ ! -z "$list_switch" ]
then
    list_servers
fi

if [ ! -z "$server_remote_name" ]
then
    get_server_info "$server_remote_name"
fi

if [ ! -z "$ip_switch" ] || [ ! -z "$port_switch" ]
then
    if [ ! -z "$ip_switch" ]
    then
        echo -e "${access_ip_port[0]}"
    fi
    if [ ! -z "$port_switch" ]
    then
        echo -e "${access_ip_port[1]}"
    fi
else
    if [ ! -z "$access_ip_port" ]
    then
        echo -e "IP:\t${access_ip_port[0]}"
        echo -e "PORT:\t${access_ip_port[1]}"
    fi
fi


