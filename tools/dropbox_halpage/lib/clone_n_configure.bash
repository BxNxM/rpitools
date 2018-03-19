#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Dropbox_Uploader_path="${MYDIR}/Dropbox-Uploader"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
APIKEY="$($confighandler -s EXTIPHANDLER -o oauth_access_token)"

if [ ! -d "$Dropbox_Uploader_path" ]
then
    echo -e "Clone https://github.com/andreafabrizi/Dropbox-Uploader.git"
    git clone https://github.com/andreafabrizi/Dropbox-Uploader.git

    echo -e "ADD permissions +x"
    chmod +x "${MYDIR}/Dropbox-Uploader/dropbox_uploader.sh"

    echo -e "Create dropbox_uploader key config: ~/.dropbox_uploader"
    echo -e "OAUTH_ACCESS_TOKEN=${APIKEY}" > ~/.dropbox_uploader
else
    echo -e "Dropbox_Uploader is ready to use"
fi
