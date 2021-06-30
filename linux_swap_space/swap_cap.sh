#!/bin/bash
# swap_cap.sh
# 202106281901 
# append a csv file with PID, Swap memory amount, current time stamp, process name for all processes that have NON-ZERO Swap
#
# check that number of arguments is 1
if [ "$#" -ne 1 ]; then
    echo "error: one arguments required, 1: capture file path and name"
    exit 2
fi

# capture csv file
CAP_FILE="$1"
# record current system uptime
UP_TIME=$(cat /proc/uptime | cut -d" " -f1)
# record current UTC system timestamp in seconds
Z_TS=$(date +"%s")

# insert a record with current system uptime, PID of -1 so as not to clash with real process records
echo "-1, $UP_TIME, \"\", $Z_TS, \"swap_cap.sh\"" >> $CAP_FILE

# get swap file usage for each running process

for file in /proc/*/status ;
    do
        if [[ -f "$file" ]];
        then
            Z_NAME=$(awk '/^Name/{print $2}' $file)
            Z_PID=$(awk '/^Pid/{print $2}' $file)
            Z_SWAP=$(awk '/^VmSwap/{print $2}' $file)
            Z_MULT=$(awk '/^VmSwap/{print $3}' $file)

            # get full command line name for process
            if [ -f "/proc/$Z_PID/cmdline" ];
            then
                # remove any null characters and trim spaces 
                Z_CMD=$(cat /proc/$Z_PID/cmdline | tr '\000' ' ');
                Z_CMD=$(echo "$Z_CMD" | tr -s " ")
            else
                # no process command line found
                Z_CMD="..."
            fi

            # if process has swap space allocated, then output a line for the process
            if [[ $Z_SWAP =~ ^-?[0-9]+$ ]] && [[ $Z_SWAP -gt 0 ]];
            then
                # record format : PID, swap used, swap multiplier, system timestamp, process command line
                echo "$Z_PID, $Z_SWAP, \"$Z_MULT\", $Z_TS, \"$Z_CMD\"" >> $CAP_FILE;
            fi
        fi
    done

