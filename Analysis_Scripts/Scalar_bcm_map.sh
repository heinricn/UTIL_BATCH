#!/bin/bash

echo "Starting Replay script"
echo "I take as arguments the Run Number and max number of events!"
RUNNUMBER=$1
MAXEVENTS=-1
### Check you've provided the an argument
if [[ $1 -eq "" ]]; then
    echo "I need a Run Number!"
    echo "Please provide a run number as input"
    exit 2
fi
if [[ ${USER} = "cdaq" ]]; then
    echo "Warning, running as cdaq."
    echo "Please be sure you want to do this."
    echo "Comment this section out and run again if you're sure."
    exit 2
fi          

# Set path depending upon hostname. Change or add more as needed  
if [[ "${HOSTNAME}" = *"farm"* ]]; then  
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/"
    if [[ "${HOSTNAME}" != *"ifarm"* ]]; then
	#source /site/12gev_phys/softenv.sh 2.4
	source /apps/root/6.18.04/setroot_CUE.bash
    fi
    cd "/group/c-pionlt/hcana/"
    source "/group/c-pionlt/hcana/setup.sh"
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh"
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt"
    #source /site/12gev_phys/softenv.sh 2.4
    source /apps/root/6.18.04/setroot_CUE.bash
    cd "/group/c-pionlt/hcana/"
    source "/group/c-pionlt/hcana/setup.sh" 
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh" 
elif [[ "${HOSTNAME}" = *"cdaq"* ]]; then
    REPLAYPATH="/home/cdaq/hallc-online/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"phys.uregina.ca"* ]]; then
    REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_lt"
fi
cd $REPLAYPATH

echo -e "\n\nStarting Replay Script\n\n"
if [ ! -f "$UTILPATH/ROOTfiles/Scalers/coin_replay_scalers_${RUNNUMBER}_${MAXEVENTS}.root" ]; then
#    eval "$REPLAYPATH/hcana -l -q \"UTIL_PION/scripts/replay/PionLT/replay_coinscalers.C($RUNNUMBER,$MAXEVENTS)\""
    eval "$REPLAYPATH/hcana -l -q -b \"SCRIPTS/COIN/SCALERS/replay_coin_scalers.C(${RUNNUMBER},${MAXEVENTS})\""
else echo "Found Scalar replay, Skipping to bcm current map"
fi

cd "CALIBRATION/bcm_current_map"
echo "Starting BMC Current map"
echo "Running Command: .x run.C(\"${REPLAYPATH}/ROOTfiles/Scalers/coin_replay_scalers_${RUNNUMBER}_${MAXEVENTS}.root\")"
#cd "$REPLAYPATH/CALIBRATION/bcm_current_map"
#root -b -l<<EOF 
#	.L ScalerCalib.C+
#	.x run.C("${REPLAYPATH}/ROOTfiles/Scalers/coin_replay_scalers_${RUNNUMBER}_${MAXEVENTS}.root")
#	.q  
#EOF
#    echo "Moving output file"
#    mv bcmcurrent_$RUNNUMBER.param $REPLAYPATH/PARAM/HMS/BCM/CALIB/bcmcurrent_$RUNNUMBER.param

if [ ! -f "$UTILPATH/ROOTfiles/Scalers/coin_replay_scalers_${RUNNUMBER}_${MAXEVENTS}.root" ]; then
    eval "$REPLAYPATH/hcana -l -q -b \"SCRIPTS/COIN/SCALERS/PionLT/replay_coin_scalers.C($RUNNUMBER,${MAXEVENTS})\""
    cd "$REPLAYPATH/CALIBRATION/bcm_current_map"
    root -b -l<<EOF 
.L ScalerCalib.C
.x run.C("${UTILPATH}/ROOTfiles/Scalers/coin_replay_scalers_${RUNNUMBER}_${MAXEVENTS}.root")
.q  
EOF
    mv bcmcurrent_${RUNNUMBER}.param $REPLAYPATH/PARAM/HMS/BCM/CALIB/bcmcurrent_$RUNNUMBER.param
    echo "moving output: mv bcmcurrent_${RUNNUMBER}.param $REPLAYPATH/PARAM/HMS/BCM/CALIB/bcmcurrent_$RUNNUMBER.param"
    cd $REPLAYPATH
else echo "Scaler replayfile already found for this run in $REPLAYPATH/ROOTfiles/Scalers - Skipping scaler replay step"
fi

exit 0
