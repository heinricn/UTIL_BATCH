#!/bin/bash

#UNNUMBER=$1
### Check you've provided the first argument  
RunList=$1
if [[ -z "$1" ]]; then
    echo "I need a run list process!"
    echo "Please provide a run list as input"
    exit 2
fi

REPLAYPATH="/u/group/c-pionlt/USERS/heinricn/hallc_replay_lt/"

while IFS='' read -r line || [[ -n "$line" ]]; do
                echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                echo "Run number read from file: $line"
                echo ""
                ##Run number#
                RUNNUMBER=$line
                
                cd "$REPLAYPATH/CALIBRATION/"
                root -l -b -q "getCoinOffset.C(\"$REPLAYPATH/ROOTfiles/Analysis/PionLT/Pion_coin_replay_production_${RUNNUMBER}_-1.root\",$RUNNUMBER)"

done < "$RunList"
