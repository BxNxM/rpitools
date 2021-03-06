#!/bin/bash

arg_helper_lolcat="$SETUPLOLCAT"

function setupmessage() {
    # setupmessage handler function
    local msg="$1"
    if [ ! -z "$msg" ]
    then
        if [ -z "$RRPITOOLS_LOG" ]
        then
            RRPITOOLS_LOG="${MYDIR}/cache/rpitools.log"
        fi
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ rpitools ]${NC} $msg"
        echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${YELLOW}[ rpitools ]${NC} $msg" >> "$RRPITOOLS_LOG"
    fi
}

function instantiation_uuid_handler() {
    if [ ! -f "$cache_instantiation_uuid_path" ]
    then
        setupmessage "Create instantiation UUID to detect specific installation."
        export instantiation_UUID="$(cat /proc/sys/kernel/random/uuid)"
        echo "$instantiation_UUID" > "$cache_instantiation_uuid_path"
        setupmessage "\tUUID: $instantiation_UUID"
    else
        setupmessage "Instantiation UUID already exists."
        export instantiation_UUID="$(cat "$cache_instantiation_uuid_path")"
        setupmessage "\tUUID: $instantiation_UUID"
   fi
}

function logo() {
    local logo_text="${YELLOW}"
    logo_text+=" _____  _____  _____  _   _ ______\n"
    logo_text+="/  ___||  ___||_   _|| | | || ___ |\n"
    logo_text+="\ \'--.| |__    | |  | | | || |_/ /\n"
    logo_text+=" \`--. \|  __|   | |  | | | ||  __/ \n"
    logo_text+="/\__/ /| |___   | |  | |_| || |    \n"
    logo_text+="\____/ \____/   \_/   \___/ \_|    rpitools${NC}\n"
    echo -e "$logo_text"
}

function set_rpiconfig_permissions() {
    if [ -e "${RPITOOLS_CONFIG}" ]
    then
        setupmessage "(Re)Set config permissions (-rw-------): ${RPITOOLS_CONFIG}"
        chmod go-rw "${RPITOOLS_CONFIG}"
    else
        setupmessage "Config NOT exists: ${RPITOOLS_CONFIG} [!!!]"
    fi
}

function set_requirements_on_host_side() {
    echo -e "DETECTED DEVICE: ${DEVICE}"
    local raspbian_lite_image_s=($(ls -1 "${HOME}/Downloads/" | grep raspbian-stretch-lite.img))
    if [ "$DEVICE" == "LINUX" ]
    then
        if [ "${#raspbian_lite_image_s[@]}" -eq 0 ]                             # raspbian lite image not exists in Downloads folder
	then
	    setupmessage "Linux rpitools requirements installing..."
            "${REPOROOT}/prepare/hostprepare/linux/prepare_sytem_for_rpitools.bash"
	else
	    setupmessage "Linux rpitools requirements already installed."
	fi
    elif [ "$DEVICE" == "MACOS" ]
    then
        if [ "${#raspbian_lite_image_s[@]}" -eq 0 ]                             # raspbian lite image not exists in Downloads folder
	then
	    setupmessage "macOS rpitools requirements installing..."
            "${REPOROOT}/prepare/hostprepare/macos/prepare_sytem_for_rpitools.bash"
	else
	    setupmessage "macOS rpitools requirements already installed."
	fi
    fi
}

function deploy_mode_text() {
    setupmessage "================================="
    setupmessage "${LIGHT_GREEN}DEPLOY MODE${NC} rpitools - WELCOME :D"
    setupmessage "================================="
    setupmessage "${LIGHT_GREEN}[1]${NC} Set your configuration: RUN COMMAND:  ${LIGHT_GREEN}confeditor${NC}"
    setupmessage "${LIGHT_GREEN}[2]${NC} Run this script in order:"
    cd "${REPOROOT}/prepare/sd_card"
    ls -l "${REPOROOT}/prepare/sd_card"
}

function set_deploy_mode_aliases_and_install_requirements() {
    # Set two quick config access interface:
    alias confeditor="${CONFEDITOR}"
    alias confighandler="${CONFIGHANDLER}"
    if [[  "$DEVICE" == "LINUX" ]] || [[ "$DEVICE" == "OTHER" ]] || [[ "$DEVICE" == "MACOS" ]]
    then
        if [ "$arg_helper_lolcat" == "true" ]
        then
            echo -e "QUICK COMMANDS WAS SET:\nconfeditor -h\nconfighandler -h" | lolcat
        else
            echo -e "QUICK COMMANDS WAS SET:\nconfeditor -h\nconfighandler -h"
        fi
        set_requirements_on_host_side
        deploy_mode_text
        return 0
    fi
}

function run_source_FALSE_if_are_NOT_on_raspberrypi() {
    # exit if we are not on raspberyy pi
    if [[ "$OS" != "GNU/Linux" ]] || [[ "$DEVICE" != "RASPBERRY" ]]
     then
        # rpitools configuration access from anywhere
        setupmessage "[INFO] For configuiration use: confeditor OR confighandler"
        setupmessage "[INFO] [MAIN SCRIPT] This script works on raspbian properly, this OS $OS DEVICE $DEVICE is not supported! => DEPLOYMENT MODE"
        run_source=false
    fi
}

function setup_main_on_raspberrypi() {
    # raspberry pi side of configuration
    if [ -z "$run_source" ] && [ "$run_source" != "false" ]
    then
        # set DISPLAY=:0 if xinit is run
        xinitrx_is_run=$(ps aux | grep "[x]initrc")
        if [ "$xinitrx_is_run" != "" ]
        then
            # set display environment (for PIXEL startx)
            setupmessage "Set DISPLAY env - gui is run"
            export DISPLAY=:0
        fi

        # restore existing backup
        output=$(pushd "${REPOROOT}/tools/"; ./cache_restore_backup.bash restore; popd)
        echo -e "$output"

        # security config permission set
        set_rpiconfig_permissions

        # Run configurations on the system
        "${REPOROOT}/prepare/system/configure_wpasupplient_and_configtxt_and_cmdlinetxt.bash"

        # config files list
        file_to_link_list=("/etc/wpa_supplicant/wpa_supplicant.conf" \
                           "/lib/systemd/system/" \
                           "/boot/config.txt" \
                           "/var/log" \
                           "/etc/fstab" \
                           "/etc/transmission-daemon/settings.json" \
                           "/etc/logrotate.conf" \
                           "/etc/hostname" \
                           "/etc/hosts" \
                           "/etc/dphys-swapfile" \
                           "/boot/cmdline.txt" \
                           "/etc/modules-load.d/raspberrypi.conf" \
                           "${RPITOOLS_CONFIG}" \
                           "/etc/samba/smb.conf" \
                           "/var/www/html/" \
                           "/etc/systemd/journald.conf" \
                           "/etc/modules" \
                           "/etc/apache2/apache2.conf" \
                           "/etc/motion/motion.conf" \
                           "/etc/default/motion" \
                           "/etc/ssh/sshd_config" \
                           "${HOME}/welcomeColor.dat" \
                           "/etc/apache2/sites-enabled/000-default.conf" \
                           "/etc/dhcpcd.conf" \
                           "/etc/minidlna.conf" \
                           "/var/lib/transmission-daemon/info/torrents" \
                           "/etc/exports" \
                           "/etc/apt/sources.list" \
                           "/etc/dphys-swapfile" \
                           "/opt/retropie/configs/all/retroarch.cfg" \
                           "${REPOROOT}/gpio/oled_128x64/lib/pages/" \
                           "/var/spool/cron/crontabs/" \
                           "${REPOROOT}/autodeployment/config/" \
                           "/etc/network/interfaces" \
                           "${REPOROOT}/tools/autosync/sync_configs/" )
        # linking config files and used folders under config folder
        for file_path in "${file_to_link_list[@]}"
        do
            filename=$(basename "$file_path")
            extension="${filename##*.}"
            filename="${filename%.*}"

            # make directory extension correction
            if [ -d "$file_path" ]
            then
                extension=""
            else
                if [ "$extension" == "$filename" ]
                then
                    extension=""
                else
                    extension=".$extension"
                fi
            fi

            # make links if not exists
            if [  -e "$REPOROOT/config/${filename}${extension}" ]
            then
                setupmessage "$REPOROOT/config/${filename}${extension} is already linked"
            else
                if [ -e "${file_path}" ]
                then
                    setupmessage "Linking: ln -s ${file_path} $REPOROOT/config/${filename}${extension}"
                    ln -s "${file_path}" "$REPOROOT/config/${filename}${extension}"
                else
                    setupmessage "Linking not possible: ${file_path} not exists (yet)."
                fi
            fi
        done

        # validate custom - user config based on template
        "${CONFIGHANDLER}" -v
        exit_code="$?"
        if [ "$exit_code" -ne 0 ]
        then
            echo -e "Set your configuration berfore continue!\n${GREEN}confeditor, and press D${NC}"
            INVALID_CONFIG="TRUE"
        else
            echo -e "Your configuration is valid :D"
            INVALID_CONFIG="FALSE"
        fi

        if [ "$INVALID_CONFIG" == "FALSE" ]
        then
            # set custom hostname
            . ${REPOROOT}/autodeployment/lib/set_custom_hostname/set_custom_hostname.bash

            # set custom password for the linux user
            . ${REPOROOT}/prepare/system/custom_user.bash                   # default user - custom hostname

            # set vimrc
            if [ -f ~/.vimrc ]
            then
                setupmessage "~/.vimrc is already set"
            else
                cp ${REPOROOT}/template/vimrc ~/.vimrc
                setupmessage "cp ${REPOROOT}/template/vimrc ~/.vimrc ...DONE"
            fi

            # source custom aliases
            if [ -z $RPITOOLS_ALIASES ]
            then
                source ${REPOROOT}/template/aliases
                setupmessage "${REPOROOT}/template/aliases source ...DONE"
                export RPITOOLS_ALIASES="true"
            else
                setupmessage "${REPOROOT}/template/aliases is already sourced"
            fi

            if [ -e ~/.bash_aliases ]
            then
                setupmessage "~/.bash_aliases is already exists."
            else
                setupmessage "Create ~/.bash_aliases with ${REPOROOT}/template/aliases"
                echo -e "source ${REPOROOT}/template/aliases" > ~/.bash_aliases
            fi

            # set ssh folder
            if [ ! -d ~/.ssh ]
            then
                setupmessage "Create ~/.ssh folder and ~/.ssh/authorized_keys file"
                mkdir ~/.ssh
                echo "" > ~/.ssh/authorized_keys
                setupmessage "Set your public key (id_pub.rsa) for pwdless ssh in ~/.ssh/authorized_keys"
            else
                if [ -e ~/.ssh/authorized_keys ]
                then
                    is_set=$(cat ~/.ssh/authorized_keys)
                    if [ "$is_set" == "" ]
                    then
                       setupmessage "Set your public key (id_pub.rsa) for pwdless ssh in ~/.ssh/authorized_keys"
                    else
                       setupmessage "~/.ssh/authorized_keys is already set"
                    fi
                else
                    setupmessage "Create ~/.ssh/authorized_keys file."
                    echo "" > ~/.ssh/authorized_keys
                    setupmessage "Set your public key (id_pub.rsa) for pwdless ssh in ~/.ssh/authorized_keys"
                fi
            fi

            setupmessage "Set network interfaces for the expected behaviour"
            echo -e $(. "${REPOROOT}/prepare/system/network/setup_network_interfaces.bash")

            . "${REPOROOT}/prepare/system/hack_apt_sources.bash"
            # update once (first run ever) before install apps
            is_installed_file_indicator="$REPOROOT/cache/.first_boot_update_update_installed"
            if [ -e "$is_installed_file_indicator" ]
            then
                setupmessage "After first boot update already done"
            else
                setupmessage "Make updates after first boot."
                . ${REPOROOT}/prepare/system/install_updates.bash
                if [ "$?" -eq 0 ]
                then
                   echo "$(date) First boot update done" > "$is_installed_file_indicator"
                else
                    setupmessage "ERROR: ${REPOROOT}/prepare/system/install_updates.bash"
                fi
            fi

            # install tools apps
            setupmessage "Install requested programs from list ${REPOROOT}/template/programs.dat:"
            . ${REPOROOT}/prepare/system/install_apps.bash

            # set up security stuffs
            . ${REPOROOT}/prepare/system/security.bash

            # automaticly mount connected devices -  add to fstab - and mount it
            setupmessage "PREPARE CONNECTED DISKS WHICH CONTAINS DISKCONF.JSON"
            sudo "${DISKHANDLER}" -p 2>&1 | tee -a "$RRPITOOLS_LOG"
            setupmessage "READ - ADD - MOUNT CONNECTED DEVICES AND CREATE STORAGE STRUCTURE"
            sudo "${DISKHANDLER}" -s -m 2>&1 | tee -a "$RRPITOOLS_LOG"
            sudo "${DISKHANDLER}" -t 2>&1 | tee -a "$RRPITOOLS_LOG"

            # Adafruit repo - install oled library
            if [ ! -e "${REPOROOT}/gpio/Adafruit_Python_SSD1306" ]
            then
                setupmessage "Install Adafruit_Python_SSD1306"
                pushd gpio

                setupmessage "Clone git repository: git clone https://github.com/adafruit/Adafruit_Python_SSD1306.git"
                git clone https://github.com/adafruit/Adafruit_Python_SSD1306.git
                if [ "$?" != 0 ]
                then
                    setupmessage "git clone - failed"
                    source ${REPOROOT}/setup
                else
                    setupmessage "Installation: cd Adafruit_Python_SSD1306 && sudo python setup.py install"
                    cd Adafruit_Python_SSD1306
                    sudo python setup.py install
                    if [ "$?" != 0 ]
                    then
                        setupmessage "sudo python setup.py install - failed"
                        source $REPOROOT/setup
                    fi
                    cd -
                fi

                popd
            else
                setupmessage "Adafruit_Python_SSD1306 already installed"
            fi

            # set welcome comsole settings
            welcome_screen_settings_output=$(${REPOROOT}/tools/welcome_config/set_welcome_screen.bash)
            setupmessage "$welcome_screen_settings_output"

            # run postinstall deplyments after reboot
            if [ -e "${REPOROOT}/cache/.first_run_reboot_done" ]
            then
                # set autodeployment post scripts
                if [ -e "$POST_CONFIG" ]
                then
                    setupmessage "Run autodeployment scripts."
                    . "$POST_CONFIG"
                else
                    setupmessage "Autodeployment post scripts not found: $POST_CONFIG"
                fi
            else
                setupmessage "AUTODEPLOYMENT: Waiting for initial first reboot! (Run autodeployments scrits after reboot...)"
            fi

            # craate system wide commands
            . "${REPOROOT}/prepare/system/set_system_wide_commands.bash"

            # first run reboot
            if [ ! -e "${REPOROOT}/cache/.first_run_reboot_done" ]
            then
                echo -e "First run reboot executing..."
                echo "$(date)" > "${REPOROOT}/cache/.first_run_reboot_done"
                sudo reboot now
            elif [ ! -e "${REPOROOT}/cache/.reboot_before_finalise_installation" ]
            then
                echo -e "Last reboot before instantiation done [finalise ufw setting after boot up again]"
                echo "$(date)" > "${REPOROOT}/cache/.reboot_before_finalise_installation"
                sudo reboot now
            fi

            # successfull instantiation indicator
            if [ ! -e "$instantiation_done_path" ]
            then
                setupmessage "rpitools Instantiation done"
                echo "$(date)" > "$instantiation_done_path"
            fi

            # create custom UUID for this specific install to identify it
            instantiation_uuid_handler

            # comfort function for storage access
            link_storage_under_rpitools_home

            setupmessage "Router config:"
            "${REPOROOT}/tools/create_router_setup.bash"

            setupmessage "Set system backup scheduling:"
            # workaround for crontab get backup config data
            ("${REPOROOT}/tools/backuphandler/create_data_for_cron.bash")
            # set backup in crontab
            "${REPOROOT}"/tools/backuphandler/cron_backup_handler.bash

            setupmessage "Set autosync function if required"
            echo -e $("${REPOROOT}/tools/autosync/set_in_cron.bash")

            setupmessage "Set up hAlarm service for advanced system monitoring and healing."
            echo -e $("${REPOROOT}/tools/HA_AlarmSystem/systemd_setup/set_service.bash")

            # printout full elapsed time
            echo -e "${YELLOW}"
            elapsed_time "stop"
            echo -e "${NC}"

            # backup modification configs
            output=$(pushd "${REPOROOT}/tools/"; ./cache_restore_backup.bash backup; popd)
            echo -e "$output"
        fi
    fi
}

function link_storage_under_rpitools_home() {
    local storage_conf_path="${REPOROOT}/cache/storage_path_structure"
    local storage_links_path="${HOME}/storage"
    if [ -f "$storage_conf_path" ]
    then
        setupmessage "LINK STORAGE FOLDERS UNDER $HOME"

        mkdir -p "$storage_links_path"

        echo -e "Link: ${USERSPACE} -> ${storage_links_path}/$(basename ${USERSPACE})"
        rm -f "${storage_links_path}/$(basename ${USERSPACE})"
        ln -sf "${USERSPACE}" "${storage_links_path}/$(basename ${USERSPACE})"

        echo -e "Link: ${SHAREDSPACE} -> ${storage_links_path}/$(basename ${SHAREDSPACE})"
        rm -f "${storage_links_path}/$(basename ${SHAREDSPACE})"
        ln -sf "${SHAREDSPACE}" "${storage_links_path}/$(basename ${SHAREDSPACE})"

        echo -e "Link: ${OTHERSPACE} -> ${storage_links_path}/$(basename ${OTHERSPACE})"
        rm -f "${storage_links_path}/$(basename ${OTHERSPACE})"
        ln -sf "${OTHERSPACE}" "${storage_links_path}/$(basename ${OTHERSPACE})"
    fi
}

function set_rpitools_env() {

    # Set setup env vars and aliases
    MYPATH="${BASH_SOURCE[0]}"
    MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    setupmessage "GET RPITOOLS ENVIRONMENT"
    source "${MYDIR}/rpienv.bash" -f -p
    instantiation_done_path="${REPOROOT}/cache/.instantiation_done"
    alias clean_cache="rm -f ${REPOROOT}/cache/.*_installed && rm -f ${REPOROOT}/cache/rpitools.log"

    #source colors
    source "$TERMINALCOLORS"

    # start time measuring
    source "${REPOROOT}/prepare/sub_elapsed_time.bash"
    elapsed_time "start"

    logo

    cache_instantiation_uuid_path="${REPOROOT}/cache/.instantiation_UUID"
}

# =============================================== MAIN =============================================== #
# SET UP ENVIRONMENT FOR RPITOOLS
set_rpitools_env

# DEPLOYMENT SIDE PREPARATION
set_deploy_mode_aliases_and_install_requirements

# RASPBERRY PI SIDE OPERATIONS
run_source_FALSE_if_are_NOT_on_raspberrypi
setup_main_on_raspberrypi
