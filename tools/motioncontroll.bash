#!/bin/bash

function motioncontroll() {
    cmd="$1"
    service="motion"
    if [ "$cmd" != "" ]
    then
        echo -e "$(echo $service | awk "{print toupper(\$0)}") CMD: $cmd"
        sudo systemctl "$cmd" "$service"
    fi
    echo -e "$(echo $service | awk "{print toupper(\$0)}") STATUS: $(sudo systemctl is-active $service)"
}

motioncontroll $@
