#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"

confighandler="/home/$USER/rpitools/autodeployment/bin/ConfigHandlerInterface.py"
autorun="$($confighandler -s KODI -o autorun)"
desktop_icon="$($confighandler -s KODI -o desktop_icon)"

function add() {
    local text="$1"
    local where="$2"
    if [ ! -z "$text" ]
    then
        is_set="$(sudo cat "$where" | grep -v grep | grep "$text")"
        #echo -e "sudo cat $where | grep -v grep | grep \'$text\'\nis_set: $is_set"
        if [ "$is_set" == "" ]
        then
            echo -e "Set autoload kodi in /home/$USER/.profile"
            echo -e "\n${text}" >> "$where"
        else
            #echo -e "text is alreay added: $text"
            is_run="$(ps aux | grep -v grep | grep 'kodi/kodi.bin')"
            #echo -e "IS RUN: $is_run"
            if [ "$is_run" == "" ]
            then
                echo -e "\t[ |> ] Run KODI"
                kodi &
            else
                echo -e "\t[ |> ] KODI is already running"
            fi
        fi
    fi
}

function remove() {
    local text="$1"
    local where="$2"
    if [ ! -z "$text" ]
    then
        is_set="$(sudo cat "$where" | grep -v grep | grep "$text")"
        #echo -e "sudo cat $where | grep -v grep | grep $text\nis_set: $is_set"
        if [ "$is_set" != "" ]
        then
            sudo sed -i 's|'"${text}"'|'""'|g' "$where"
        fi
    fi
}

# DESKTOP ICON
autorun_icon_path="/home/$USER/Desktop/KODI"
if [ ! -e "/home/$USER/Desktop" ]
then
    mkdir "/home/$USER/Desktop"
fi
if [ "$desktop_icon" == "True" ] || [ "$desktop_icon" == "true" ]
then
    if [ ! -e "$autorun_icon_path" ]
    then
        echo -e "[ |> ] Create KODI desktop icon"
        echo -e "#!/bin/bash\n/usr/bin/kodi &" > "$autorun_icon_path"
        chmod +x "$autorun_icon_path"
    else
        echo -e "[ |> ] KODI desktop icon is already created."
    fi
else
    if [ -e "$autorun_icon_path" ]
    then
        rm -f "$autorun_icon_path"
    fi
fi

# AUTORUN SET
run_command="${MYDIR_}/kodi_runner.bash"
profile_path="/home/$USER/.profile"
if [ "$autorun" == "True" ] || [ "$autorun" == "true" ]
then
    add "$run_command" "$profile_path"
else
    remove "$run_command" "$profile_path"
fi
