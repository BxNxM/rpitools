#!/bin/bash

function motioncontroll() {
    cmd="$1"
    short_status="$2"
    service="motion"

    if [ "$cmd" == "--help" ] || [ "$cmd" == "-h" ] || [ "$cmd" == "" ]
    then
        echo -e "MOTION SERVICE QUICK CONTROLLER"
        echo -e "start\t\t - start motion camera"
        echo -e "stop\t\t - stop motion camera"
        echo -e "status\t\t - show status of motion camera"
        echo -e "status --short\t - shows short status of motion camera"
        exit 0
    fi

    if [ "$cmd" != "" ]
    then
        echo -e "$(echo $service | awk "{print toupper(\$0)}") CMD: $cmd"
        if [ "$cmd" == "status" ]
        then
            if [ "$short_status" != "--short" ]
            then
                sudo systemctl "$cmd" --no-pager "$service"
            fi
        else
            sudo systemctl "$cmd" "$service"
        fi
        echo -e "$(echo $service | awk "{print toupper(\$0)}") STATUS: $(sudo systemctl is-active $service)"
    fi
}

motioncontroll $@
