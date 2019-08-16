#!/bin/bash

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

source "$TERMINALCOLORS"

autorun="$($CONFIGHANDLER -s KODI -o autorun)"
desktop_icon="$($CONFIGHANDLER -s KODI -o desktop_icon)"

source "${MYDIR}/../message.bash"
_msg_title="KODI SETUP"

function add() {
    local text="$1"
    local where="$2"
    if [ ! -z "$text" ]
    then
        is_set="$(sudo cat "$where" | grep -v grep | grep "$text")"
        #echo -e "sudo cat $where | grep -v grep | grep \'$text\'\nis_set: $is_set"
        if [ "$is_set" == "" ]
        then
            _msg_ "Set autoload kodi in $HOME/.profile"
            echo -e "\n${text}" >> "$where"
        else
            #echo -e "text is alreay added: $text"
            is_run="$(ps aux | grep -v grep | grep 'kodi/kodi.bin')"
            #echo -e "IS RUN: $is_run"
            if [ "$is_run" == "" ]
            then
                _msg_ "\t[ |> ] Run KODI"
                kodi &
            else
                _msg_ "\t[ |> ] KODI is already running"
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
autorun_icon_path="$HOME/Desktop/KODI"
if [ ! -e "$HOME/Desktop" ]
then
    mkdir "$HOME/Desktop"
fi
if [ "$desktop_icon" == "True" ] || [ "$desktop_icon" == "true" ]
then
    if [ ! -e "$autorun_icon_path" ]
    then
        _msg_ "[ |> ] Create KODI desktop icon"
        echo -e "#!/bin/bash\n/usr/bin/kodi &" > "$autorun_icon_path"
        chmod +x "$autorun_icon_path"
    else
        _msg_ "[ |> ] KODI desktop icon is already created."
    fi
else
    if [ -e "$autorun_icon_path" ]
    then
        rm -f "$autorun_icon_path"
    fi
fi

# AUTORUN SET
run_command="${MYDIR}/kodi_runner.bash"
profile_path="$HOME/.profile"
if [ "$autorun" == "True" ] || [ "$autorun" == "true" ]
then
    add "$run_command" "$profile_path"
else
    remove "$run_command" "$profile_path"
fi
