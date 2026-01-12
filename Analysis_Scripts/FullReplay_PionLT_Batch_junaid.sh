#! /bin/bash

#
# Description:
# ======================================================
# Created:  Muhammad Junaid
# University of Regina, CA
# Date :18-Dec-2023
# ======================================================
# 

# Set path depending upon hostname. Change or add more as needed  
if [[ "${HOSTNAME}" = *"farm"* ]]; then  
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt"
    if [[ "${HOSTNAME}" != *"ifarm"* ]]; then
	#source /site/12gev_phys/softenv.sh 2.4
 	#source /apps/root/6.18.04/setroot_CUE.bash
        module use /cvmfs/oasis.opensciencegrid.org/jlab/scicomp/sw/el9/modulefiles
        module load root/6.24.08-gcc11.4.0
    fi
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh"
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt"
    #source /site/12gev_phys/softenv.sh 2.4
    source /apps/root/6.18.04/setroot_CUE.bash
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh" 
elif [[ "${HOSTNAME}" = *"cdaq"* ]]; then
    REPLAYPATH="/home/cdaq/hallc-online/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"phys.uregina.ca"* ]]; then
    REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_lt"
fi

ls -lhtr hcana

UTILPATH="${REPLAYPATH}/UTIL_PION"
cd $REPLAYPATH
echo ""
echo "Starting physics analysis of PionLT data"
echo "Required arguments are run type, run number and max events"
echo ""
echo "Run number must be a positive integer value"
echo "Run type must be one of - Prod - LumiHMS - LumiSHMS - LumiCoin - HeePSingHMS - HeePSingSHMS - HeePCoin - pTRIG6 - Case sensitive!"

RUNTYPE=$1
RUNNUMBER=$2
MAXEVENTS=$3
# Need to change these a little, should check whether arguments are good or not REGARDLESS of whether they're blank
if [[ -z "$1" || ! "$RUNTYPE" =~ Prod|LumiHMS|LumiSHMS|LumiCoin|HeePSingHMS|HeePSingSHMS|HeePCoin|pTRIG6 ]]; then # Check the 2nd argument was provided and that it's one of the valid options
    echo ""
    echo "I need a valid run type"
    while true; do
	echo ""
	read -p "Please type in a run type from - Prod - LumiHMS - LumiSHMS - LumiCoin - HeePSingHMS - HeePSingSHMS - HeePCoin - pTRIG6 - Case sensitive! - or press ctrl-c to exit : " RUNTYPE
	case $RUNTYPE in
	    '');; # If blank, prompt again
	    'Prod'|'LumiHMS'|'LumiSHMS'|'LumiCoin'|'HeePSingHMS'|'HeePSingSHMS'|'HeePCoin'|'pTRIG6') break;; # If a valid option, break the loop and continue
	esac
    done
fi

if [[ -z "$2" || ! "$RUNNUMBER" =~ ^-?[0-9]+$ ]]; then # Check an argument was provided and that it is a positive integer, if not, prompt for one
    echo ""
    echo "I need a valid run number - MUST be a positive integer"
    while true; do
	echo ""
	read -p "Please type in a run number (positive integer) as input or press ctrl-c to exit : " RUNNUMBER
	case $RUNNUMBER in
	    '' | *[!0-9]*);; # If the input is NOT a positive integer (or it's just an empty string), don't break the loop
	    *) break;;
	esac
    done
fi

if [[ $3 -eq "" ]]; then
    echo "Only Run Number entered...I'll assume -1 events!" 
    MAXEVENTS=-1 
fi

echo -e "\nStarting Replay Script\n"

if [[ $RUNTYPE == "Prod" ]]; then
    echo "Running production analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_Phys_Prod.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "HeePCoin" ]]; then
    echo "Running HeeP Coin analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_HeeP_Coin.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "HeePSingHMS" ]]; then
    echo "Running HMS HeeP Singles analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_HeeP_Sing_HMS.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "HeePSingSHMS" ]]; then
    echo "Running SHMS HeeP Singles analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_HeeP_Sing_SHMS.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "LumiHMS" ]]; then
    echo "Running Luminosity HMS analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_Lumi_HMS.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "LumiSHMS" ]]; then
    echo "Running Luminosity SHMS analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_Lumi_SHMS.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "LumiCoin" ]]; then
    echo "Running Lumi Coin analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_Lumi_Coin.C($RUNNUMBER,$MAXEVENTS)\""
elif [[ $RUNTYPE == "pTRIG6" ]]; then
    echo "Running production pTRIG6 analysis script - ${RUNTYPE}"
    eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/PRODUCTION/PionLT_REPLAY/FullReplay_PionLT_Phys_Prod_pTRIG6.C($RUNNUMBER,$MAXEVENTS)\""
fi
exit 0
