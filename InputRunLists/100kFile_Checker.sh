#!/bin/bash

### Stephen Kay --- University of Regina --- 07/10/20 ###
### Check if files from provided run number are in the directory specified on /volatile/, if not, save to list ###
inputFile="$1"

if [[ "${HOSTNAME}" = *"farm"* ]]; then  
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"cdaq"* ]]; then
    REPLAYPATH="/home/cdaq/hallc-online/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"phys.uregina.ca"* ]]; then
    REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_lt"
fi

cd "${REPLAYPATH}/UTIL_BATCH/InputRunLists/"

if [ -f "RunsNotInVolatile100k" ]; then
    rm "RunsNotInVolatile100k"
    else touch "RunsNotInVolatile100k"
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
    #Run number#
    runNum=$line
    if [[ ! -f "/volatile/hallc/c-pionlt/Pass1_100k_EDTM/coin_replay_Full_${runNum}_100000.root" ]]; then
	echo "100k replay for run number ${runNum} not found in /volatile"
	echo "${runNum}" >> "RunsNotInVolatile100k"
    fi
done < "$inputFile"
