#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"
confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"

configure_transmission="${MYDIR_}/../lib/configure_transmission.bash"
set_transmission_whitelist_autoedit="/home/$USER/rpitools/tools/auto_restart_transmission/systemd_setup/set_service.bash"
configure_samba="${MYDIR_}/../lib/configure_samba.bash"

_msg_title="CONFIG POST ACTIONS"
function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ $_msg_title ]${NC} - $msg"
}

function post_config_actions_done() {
    local cache_dir="$MYDIR_/../../cache/"
    local indicator_file="${cache_dir}/.post_config_actions_done"
    if [ ! -f "$indicator_file" ]
    then
        echo -e "$(date)" > "${indicator_file}"
    fi
}

# ||||||||||||||||||||||||||| #
#  POST CONFIGURATION SCRIPT  #
# ||||||||||||||||||||||||||| #

# nfs client setup
_msg_ "RUN: nfs client setup"
(. "/home/$USER/rpitools/autodeployment/lib/configure_nfs_clinet.bash")

# set media stream with minidlna
_msg_ "RUN: minidlna setup"
(. /home/$USER/rpitools/autodeployment/lib/configure_minidlna.bash)

# set nfs server
_msg_ "RUN: nfs setup"
(. /home/$USER/rpitools/autodeployment/lib/configure_nfs_server.bash)

# set samba configuration
_msg_ "RUN: configure_samba"
(. "$configure_samba")

# set memdict core service
_msg_ "RUN: set up service if needed - memDictCore"
(. "/home/$USER/rpitools/tools/socketmem/systemd_setup/set_service.bash")

# transmission install config executor
_msg_ "RUN: configure_transmission"
(. "$configure_transmission")
_msg_ "RUN: set transmission autorestart edit whitelist"
(. "$set_transmission_whitelist_autoedit")

# pixel install config executor
pixel_install="$($confighandler -s INSTALL_PIXEL -o activate)"
if [ "$pixel_install" == "True" ] || [ "$pixel_install" == "true" ]
then
    _msg_ "RUN: PIXEL install"
    (. ${MYDIR_}/../../prepare/system/install_PIXEL.bash)
else
    _msg_ "PIXEL install is not requested"
fi

# vnc install config executor
vnc_install="$($confighandler -s INSTALL_VNC -o activate)"
if [ "$vnc_install" == "True" ] || [ "$vnc_install" == "true" ]
then
    _msg_ "RUN: VNC install"
    (. ${MYDIR_}/../../prepare/system/install_vnc.bash)
else
    _msg_ "VNC install is not requested"
fi

# set oled gui core service if config requires
_msg_ "RUN: OLED GUI CORE service setup"
(. "/home/$USER/rpitools/gpio/oled_128x64/systemd_setup/set_service.bash")

# run kodi config settings
_msg_ "RUN: KODI dektop icon and bootup start if set"
(. /home/$USER/rpitools/autodeployment/lib/kodi_runner.bash)

# set dropbox halpage service if config requires
_msg_ "RUN: DROPBOX HALPAGE service setup"
(. "/home/$USER/rpitools/tools/dropbox_halpage/systemd_setup/set_service.bash")

# Configure git
(. "/home/$USER/rpitools/autodeployment/lib/configure_git.bash")

# Custom logrotate
_msg_ "RUN: custom logrotate service: log_cleaner.bash or rpitools_logrotate.service"
(. /home/$USER/rpitools/tools/log_cleaner_service/systemd_setup/set_service.bash)

# set custom apache webpage
_msg_ "RUN apache basic setup based on rpi_config and rpitools/autodeployment/lib/apache_setup/template"
apache_override_underupdate_webpage="$($confighandler -s APACHE -o override_underupdate)"
if [[ "$apache_override_underupdate_webpage" == "True" ]] || [[ "$apache_override_underupdate_webpage" == "true" ]]
then
    _msg_ "\t override_underupdate: $apache_override_underupdate_webpage"
    (. /home/$USER/rpitools/autodeployment/lib/apache_setup/setup_based_on_template.bash -f)
else
    _msg_ "\t override_underupdate: $apache_override_underupdate_webpage"
    (. /home/$USER/rpitools/autodeployment/lib/apache_setup/setup_based_on_template.bash)
fi
# set rgb service for faster access and load time
_msg_ "RUN: set up service if needed - rgb_led_controller"
(. "/home/$USER/rpitools/gpio/rgb_led/systemd_setup/set_service.bash")

# install and configure motion camera service
_msg_ "RUN: motion install and configure"
(. "/home/$USER/rpitools/autodeployment/lib/motion/install_n_configure.bash")

# motion video stream over apache server setup, run after apache config
_msg_ "RUN: motion video stream forwarding"
(. /home/$USER/rpitools/autodeployment/lib/motion_remote_video_stream_over_apache.bash)

# Set status file under cache
post_config_actions_done

# ||||||||||||||||| #
#  RUN USER SCRIPT  #
# ||||||||||||||||| #
userscript_is_activated="$($confighandler -s USER_SPACE -o activate)"
if [ "$userscript_is_activated" == "true" ] || [ "$userscript_is_activated" == "True" ]
then
    _msg_ "USER SCRIPT WAS ACTIVATED"
    _msg_ "\t$($confighandler --user_script)"
    path="$($confighandler -s USER_SPACE -o path)"
    _msg_ "RUN: bash $path"
    _msg_ "\n################################## $(date '+%Y.%m.%d %H:%M:%S') ##################################"
    sudo bash "$path"
    echo -e "################################## $(date '+%Y.%m.%d %H:%M:%S') ##################################"
else
    _msg_ "USER SCRIPT WAS NOT ACTIVATED"
fi
