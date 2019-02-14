#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../colors.bash"

_msg_title="apt source extend"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ $_msg_title ]${NC} - $msg"
}

function add_repo_keys() {
    _msg_ "Add repo keys for the propare usage"
    sudo gpg --keyserver pgpkeys.mit.edu --recv-key CCD91D6111A06851
    sudo gpg --armor --export CCD91D6111A06851 | apt-key add -
}

function extend_apt_source_list() {
    local mirror="deb http://repozytorium.mati75.eu/raspbian jessie-backports main contrib non-free"
    (grep "$mirror" /etc/apt/sources.list)
    if [ "$?" -ne 0 ]
    then
        _msg_ "add $mirror to /etc/apt/sources.list"
        sudo bash -c "echo -e $mirror >> /etc/apt/sources.list"
        sudo apt-get update
        add_repo_keys
    else
        _msg_ "$mirror already exists in /etc/apt/sources.list"
    fi
}

_msg_ "$(echo 'mati75s private repository: http://repozytorium.mati75.eu' | lolcat)"
extend_apt_source_list
#add_repo_keys
