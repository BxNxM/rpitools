#!/bin/bash
# by Paul Colby (http://colby.id.au), no rights reserved ;)
# read file for it: /proc/stat
# See man 5 proc for more help

#HandleInputs
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
arg=$1
argIsExist=false
if [ ! -z $arg ]
then
	argIsExist=true
fi
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#

PREV_TOTAL=0
PREV_IDLE=0

function GetCPULoad {
  local mode="$1"

  avgCpuLoad=0
  measureTime=4
  #measure $measureTime times
  for ((cnt=0; cnt<$measureTime; cnt++))
  do
     CPU=(`cat /proc/stat | grep '^cpu '`) # Get the total CPU statistics.
     unset CPU[0]                          # Discard the "cpu" prefix.
     IDLE=${CPU[4]}                        # Get the idle CPU time.

     # Calculate the total CPU time.
     TOTAL=0

     for VALUE in "${CPU[@]:0:4}"; do
        let "TOTAL=$TOTAL+$VALUE"
     done

     # Calculate the CPU usage since we last checked.
     let "DIFF_IDLE=$IDLE-$PREV_IDLE"
     let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
     let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
     #echo -en "\rCPU: $DIFF_USAGE%  \b\b"
     avgCpuLoad=$((avgCpuLoad + DIFF_USAGE))

     # Remember the total and idle CPU times for the next check.
     PREV_TOTAL="$TOTAL"
     PREV_IDLE="$IDLE"

     # Wait before checking again.
     sleep .1
   done

   if [ "$mode" == "-s" ]
   then
      echo -en "$((avgCpuLoad / measureTime))"
   else
      echo -en "\rCPU: $((avgCpuLoad / measureTime)) %  \b\b"
   fi
   avgCpuLoad=0
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
if [ $argIsExist == "true" ]
then
	#infinit output
	if [ $arg == "-l" ]
	then
		while true
		do
			GetCPULoad
			sleep .1
		done
        elif [ $arg == "-s" ]
        then
            GetCPULoad "-s"
	#helper menu
	elif [[ $arg == "-help" || $arg == "-h" ]]
	then
		echo -e "arg: <-l>\t write average CPU LOAD continously"
                echo -e "arg: <-s>\t outputs without format, just int"
		echo -e "arg: <>\t write one result to stdio"
		echo -e "arg: <-help or -h> helper menu" 
	fi

#default output
else
	GetCPULoad
fi
