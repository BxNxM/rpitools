#!/bin/bash

function motioncontroll() {
    cmd="$1"
    service="motion"
    if [ "$cmd" != "" ]
    then
        echo -e "$(echo $service | awk "{print toupper(\$0)}") CMD: $cmd"
        if [ "$cmd" == "status" ]
        then
            sudo systemctl "$cmd" --no-pager "$service"
        else
            sudo systemctl "$cmd" "$service"
        fi
    fi
    echo -e "$(echo $service | awk "{print toupper(\$0)}") STATUS: $(sudo systemctl is-active $service)"
}

motioncontroll $@
