#!/bin/bash

cycle_sleep_time=20

while true
do
    echo -e "QUERY SYSTEM HEALTH DATA [CYCLE $cycle_sleep_time SEC]"
    sysmonitor > /dev/null
    if [ "$?" -eq 0 ]
    then
        echo -e "\tsuccessful execution... wait $cycle_sleep_time sec"
    else
        echo -e "\tfailed execution... wait $cycle_sleep_time sec"
    fi
    sleep "${cycle_sleep_time}"
done
