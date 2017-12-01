
function elapsed_time() {
    option="$1"                 #start - stop

    if [ "$option" == "start" ]
    then
        SECONDS=0
    fi

    if [ "$option" == "stop" ]
    then
        duration=$SECONDS
        echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    fi

    if [ "$option" != "stop" ] && [ "$option" != "start" ]
    then
        echo -e "INVALID OPTION: $option (VALID: start or stop)"
    fi
}

#elapsed_time "start"
#sleep 5
#elapsed_time "stop"
