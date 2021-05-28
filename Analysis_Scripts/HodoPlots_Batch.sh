#!/bin/bash

### Nathan Heinrich -- University Of Regina -- 2021/05/27
### Script for generating summary plots for Hodoscope Calibration 
### Its recomended That you run run_batch_HodoCalib.sh for the same input run list first

RUNLIST=$1
if [[ $1 -eq "" ]]; then
    echo "I need a File with the run list!"
    echo "Please provide the name to a file in UTIL_BATCH/InputRunLists/"
    exit 2
fi

# Set replaypath depending upon hostname. Change as needed
if [[ ${USER} = "cdaq" ]]; then
    echo "Warning, running as cdaq."
    echo "Please be sure you want to do this."
    echo "Comment this section out and run again if you're sure."
    exit 2
fi       
     
# Set path depending upon hostname. Change or add more as needed  
if [[ "${HOSTNAME}" = *"farm"* ]]; then  
    REPLAYPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt"
    if [[ "${HOSTNAME}" != *"ifarm"* ]]; then
	source "/site/12gev_phys/softenv.sh 2.3"
    fi
    cd "/group/c-kaonlt/hcana/"
    source "/group/c-kaonlt/hcana/setup.sh"
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh"
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    REPLAYPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt"
    source "/site/12gev_phys/softenv.sh 2.3"
    cd "/group/c-kaonlt/hcana/"
    source "/group/c-kaonlt/hcana/setup.sh" 
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh" 
elif [[ "${HOSTNAME}" = *"cdaq"* ]]; then
    REPLAYPATH="/home/cdaq/hallc-online/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"phys.uregina.ca"* ]]; then
    REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_lt"
fi

if [[ ! -f "$REPLAYPATH/UTIL_BATCH/InputRunLists/$RUNLIST" ]]
	echo "$REPLAYPATH/UTIL_BATCH/InputRunLists/$RUNLIST not found"
	echo "Check to make sure File is in the right place!"
	echo "exiting"
	exit 2
fi

cd "$REPLAYPATH/CALIBRATION/shms_hodo_calib"


echo "Running SHMS HodoParamCompair"
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/HodoParamCompair.C(\"$REPLAYPATH/UTIL_BATCH/InputRunLists/$RUNLIST\")"

echo "Running SHMS plotBeta.C"
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/plotBeta.C(\"$REPLAYPATH/UTIL_BATCH/InputRunLists/$RUNLIST\")"

echo "Running HMS HodoParamCompair"
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/HodoParamCompair.C(\"$REPLAYPATH/UTIL_BATCH/InputRunLists/$RUNLIST\")"

echo "Running HMS plotBeta.C"
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/plotBeta.C(\"$REPLAYPATH/UTIL_BATCH/InputRunLists/$RUNLIST\")"

exit 0





