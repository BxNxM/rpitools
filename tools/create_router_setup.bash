#!/bin/bash

arg_list=($@)

MYPATH="${BASH_SOURCE[0]}"
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

transmission_is_active="$($CONFIGHANDLER -s TRANSMISSION -o activate)"

# inputs
mac_address=""
ip_address=""
external_ip=""
ports_title=("ssh,sftp" "http")
ports_internal=(22 80)
ports_external=(62830 80)

config_out_path="${REPOROOT}/config/router_conf.txt"
if [ "${arg_list[0]}" == "-r" ]
then
    rm -f "$config_out_path"
fi
function config_out() {
    local msg="$*"
    echo -e "$msg"
    echo -e "$msg" >> "$config_out_path"
}

function get_mac_addresses() {
    local swp_file="/tmp/general.swp"
    (sysmonitor -g > "$swp_file")
    parameters=($(cat "$swp_file"))
    (rm -f "$swp_file")
    for ((k=0; k<"${#parameters[@]}"; k++))
    do
        par="${parameters[$k]}"
        if [[ "$par" == *"eth"* ]]
        then
            mac_address_eth="eth: ${parameters[$((k+1))]}"
        fi
        if [[ "$par" == *"wlan"* ]]
        then
            mac_address_wlan="wlan: ${parameters[$((k+1))]}"
        fi
        if [[ "$par" == *"usb"* ]]
        then
            mac_address_usb="usb: ${parameters[$((k+1))]}"
        fi
        if [[ "$par" == *"IP[0]"* ]]
        then
            ip_address="${parameters[$((k+1))]}"
        fi
        if [[ "$par" == *"External"* ]]
        then
            external_ip="${parameters[$((k+3))]}"
        fi
    done
    if [ ! -z "$mac_address_eth" ]
    then
        mac_address="$mac_address_eth"
    elif [ ! -z "$mac_address_wlan" ]
    then
        mac_address="$mac_address_wlan"
    else
        mac_address="$mac_address_usb"
    fi
}

function create_config_description() {
    get_mac_addresses

    config_out "============== Config this parameters in your router =============="
    config_out "=========== set these for external access from outside ============"
    config_out "==================================================================="
    config_out "Set your pi static access in your router"
    config_out "\tstatic ip: $ip_address"
    config_out "\tmac_address: $mac_address"
    config_out "\nPort forwarding"
    for ((i=0; i<${#ports_internal}; i++))
    do
        config_out "\tPort settings for ${ports_title[$i]}"
        config_out "\t\tinternal: ${ports_internal[$i]}"
        config_out "\t\texternal: ${ports_external[$i]}"
    done
    config_out "You can access your raspberry pi from extarnal network with your\n\
external ip: $external_ip"
    config_out "==================================================================="
    echo -e "You can access to the router config file:\n$config_out_path"
}

if [ ! -f "$config_out_path" ] || [ "${arg_list[0]}" == "-r" ]
then
    echo -e "Generate router config file..."
    create_config_description
else
    echo -e "$config_out_path already generated, for regenerate: $MYPATH -r"
fi
