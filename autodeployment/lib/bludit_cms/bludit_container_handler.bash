#!/bin/bash

# DOC: https://github.com/pdacity/bludit_docker
# THEMES: https://themes.bludit.com

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

source "${TERMINALCOLORS}"
source "${MYDIR}/../message.bash"
_msg_title="BLUDIT FLAT CMS"

#########################################
#               CONFIG                  #
#########################################
TAG="bludit_cms"
EXTERNAL_PORT=8000
BLUDIT_STORAGE_PATH="${MYDIR}/config/container_storage"
TEST=true

if [ ! -d "$BLUDIT_STORAGE_PATH" ]
then
    _msg_ "Initialize storage dir: $BLUDIT_STORAGE_PATH"
    mkdir -p "$BLUDIT_STORAGE_PATH"
fi

function clone_bludit() {
    local docker_bludit_path="${MYDIR}/config/bludit_docker"

    if [ ! -d "$docker_bludit_path" ]
    then
        _msg_ "Clone bludit docker repo"
        pushd "${MYDIR}/config"
            git clone https://github.com/pdacity/bludit_docker.git
        popd
    else
        _msg_ "Bludit was already cloned"
    fi
}

function build_container() {
    local tag="$1"
    local is_image_exists="$(docker images | grep "$tag")"
    if [ "$is_image_exists" == "" ]
    then
        _msg_ "Build bludit docker conatiner"
        pushd "${MYDIR}/config/bludit_docker"
        sudo docker build -t "$tag" .
        if [ "$?" -eq 0 ]
        then
            _msg_ "\tOK"
        else
            _msg_ "\tERROR"
        fi
        popd
    else
        _msg_ "$tag image already exists."
    fi
}

function run_container() {
    local tag="$1"
    local external_port="$2"
    local bludit_storage_path="$3"
    local is_container_exists="$(docker ps | grep "$tag")"
    if [ "$is_container_exists" == "" ]
    then
        _msg_ "Run conatiner: ${tag}_01 image: $tag:latest"
        if [ "$TEST" == "true" ]
        then
            _msg_ "\tTEST MODE ON: using non persistent storage"
            docker run --name "${tag}_01" -p "$external_port":80 -d "$tag":latest
        else
            docker run --name "${tag}_01" \
            -p "$external_port":80 \
            -v "$bludit_storage_path":/usr/share/nginx/html/bl-content \
            -d "$tag":latest
        fi
        if [ "$?" -eq 0 ]
        then
            _msg_ "\tOK"
        else
            _msg_ "\tERROR"
        fi
    else
        _msg_ "Conatiner already running: ${tag}_01 image: $tag:latest"
    fi
    docker ps | grep "$tag"
}

clone_bludit
build_container "$TAG"
run_container "$TAG" "$EXTERNAL_PORT" "$BLUDIT_STORAGE_PATH"
