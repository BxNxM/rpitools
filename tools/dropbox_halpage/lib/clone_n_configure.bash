#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Dropbox_Uploader_path="${MYDIR}/Dropbox-Uploader"
Dropbox_Uploader_runtime_path="${Dropbox_Uploader_path}/dropbox_uploader.sh"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
APIKEY="$($confighandler -s EXTIPHANDLER -o oauth_access_token)"

if [[ ! -d "$Dropbox_Uploader_path" ]] || [[ ! -e "$Dropbox_Uploader_runtime_path" ]]
then
    if [ -d "$Dropbox_Uploader_path" ]
    then
        rm -rf "$Dropbox_Uploader_path"
    fi

    echo -e "Clone https://github.com/andreafabrizi/Dropbox-Uploader.git"
    pushd "${MYDIR}/../lib"
    git clone https://github.com/andreafabrizi/Dropbox-Uploader.git
    if [ ! -d "${MYDIR}/../lib/Dropbox-Uploader" ]
    then
        echo -e "[WARNING] clone Dropbox-Uploader failed - try again"
        git clone https://github.com/andreafabrizi/Dropbox-Uploader.git
    fi
    if [ -d "${MYDIR}/../lib/Dropbox-Uploader" ]
    then
        echo -e "SUCCESS"
    else
        echo -e "FAILED"
    fi
    popd

    echo -e "ADD permissions +x"
    chmod +x "${MYDIR}/Dropbox-Uploader/dropbox_uploader.sh"

    echo -e "Create dropbox_uploader key config: ~/.dropbox_uploader"
    echo -e "OAUTH_ACCESS_TOKEN=${APIKEY}" > ~/.dropbox_uploader
else
    echo -e "Dropbox_Uploader is ready to use"
fi
