#!/bin/bash

### Stephen Kay --- University of Regina --- 12/11/19 ###
### Script for running (via batch or otherwise) the hodoscope calibration, this one script does all of the relevant steps for the calibration proces
### Note that the second part also has an additional bit where it checks for a database file based upon the run number

### 26/02/21 - SK - NOTE, this script is likely quite outdated now, needs updating.
### Major issue will be with which db file it grabs, also should probably use new cal calibration and put OUTPUT in
### Also, do the folders it's outputing to exist by default? If not they should be checked and created as needed

### 06/09/23 - NH - Updates made, will need tweeking to get running for anything but pionlt

RUNNUMBER=$1
OPT=$2
### Check you've provided the first argument  
if [[ $1 -eq "" ]]; then
    echo "I need a Run Number!"
    echo "Please provide a run number as input"
    exit 2
fi
### Check you have provided the second argument correctly
if [[ ! $2 =~ ^("HMS"|"SHMS")$ ]]; then
    echo "Please specify spectrometer, HMS or SHMS"
    exit 2
fi
### Check if a third argument was provided, if not assume -1, if yes, this is max events
if [[ $3 -eq "" ]]; then
    MAXEVENTS=-1
else
    MAXEVENTS=$3
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
    REPLAYPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt"
    #REPLAYPATH="/group/c-pionlt/online_analysis/hallc_replay_lt"
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

### Check the extra folders you'll need exist, if they don't then make them
if [ ! -d "$REPLAYPATH/DBASE/COIN/HMS_HodoCalib" ]; then
    mkdir "$REPLAYPATH/DBASE/COIN/HMS_HodoCalib"
fi

if [ ! -d "$REPLAYPATH/DBASE/COIN/SHMS_HodoCalib" ]; then
    mkdir "$REPLAYPATH/DBASE/COIN/SHMS_HodoCalib"
fi

if [ ! -d "$REPLAYPATH/PARAM/HMS/HODO/Calibration" ]; then
    mkdir "$REPLAYPATH/PARAM/HMS/HODO/Calibration"
fi

if [ ! -d "$REPLAYPATH/PARAM/SHMS/HODO/Calibration" ]; then
    mkdir "$REPLAYPATH/PARAM/SHMS/HODO/Calibration"
fi

if [ ! -d "$REPLAYPATH/CALIBRATION/hms_hodo_calib/Calibration_Plots" ]; then
    mkdir "$REPLAYPATH/CALIBRATION/hms_hodo_calib/Calibration_Plots"
fi

if [ ! -d "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots" ]; then
    mkdir "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots"
fi

eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/CALIBRATION/"$OPT"Hodo_Calib_Coin_Pt1.C($RUNNUMBER,$MAXEVENTS)\""
ROOTFILE="$REPLAYPATH/ROOTfiles/Calib/Hodo/"$OPT"_Hodo_Calib_Pt1_"$RUNNUMBER"_"$MAXEVENTS".root" 

if [[ $OPT == "HMS" ]]; then
    spec="hms"
    specL="h"
elif [[ $OPT == "SHMS" ]]; then
    spec="shms"
    specL="p"
fi

cd "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/"
#root -l -q -b "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/timeWalkHistos.C(\"$ROOTFILE\", $RUNNUMBER, \"coin\")"
#root -l -q -b "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/timeWalkCalib.C($RUNNUMBER)"

# After executing first two root scripts, should have a new .param file so long as scripts ran ok, IF NOT THEN EXIT
#if [ ! -f "$REPLAYPATH/PARAM/"$OPT"/HODO/"$specL"hodo_TWcalib_$RUNNUMBER.param" ]; then
#    echo ""$specL"hodo_TWCalib_$RUNNUMBER.param not found, calibration script likely failed"
#    exit 2
#fi
#mv "$REPLAYPATH/PARAM/"$OPT"/HODO/"$specL"hodo_TWcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/"$OPT"/HODO/Calibration/"$specL"hodo_TWcalib_$RUNNUMBER.param"

if ! grep -q "OfflineCalib_$RUNNUMBER.param" "$REPLAYPATH/DBASE/COIN/HodoCalib/standard_HodoCalib.database"; then
    echo -e "\n$RUNNUMBER - $RUNNUMBER \ng_ctp_parm_filename       = \"DBASE/COIN/HodoCalib/OfflineCalib_$RUNNUMBER.param\"\n" >> "$REPLAYPATH/DBASE/COIN/HodoCalib/standard_HodoCalib.database"
fi

# this part is written assuming that you are calibrating runs form 2021 and 2022 pionLT data.
# grabs files in param directory and finds the one that fits, then copies 
if [ $RUNNUMBER -lt 14777 ]; then
    cd "$REPLAYPATH/DBASE/COIN/Offline_PionLT2021"
    if [ $RUNNUMBER -lt 11829 ]; then
	cp "./OfflinePionLT_8977-11828.param" $REPLAYPATH/DBASE/COIN/HodoCalib/OfflineCalib_$RUNNUMBER.param
	break
    fi
    for f in ./*-*.param; do
	echo "processing $f"
	noFront=${f#*OfflinePionLT_}
	echo $noFront
	low=${noFront:0:5}
	high=${noFront:6:5}
	echo "Searching for $RUNNUMBER between $low and $high"
	if [ $RUNNUMBER -le $high ] && [ $RUNNUMBER -ge $low ]; then
	    echo "found ./OfflinePionLT_$low-$high.param copying"
	    cp "./OfflinePionLT_$low-$high.param" $REPLAYPATH/DBASE/COIN/HodoCalib/OfflineCalib_$RUNNUMBER.param
	    break
	fi
    done
else
    cd "$REPLAYPATH/DBASE/COIN/Offline_PionLT2022"
    for f in ./*-*.param; do
        echo "processing $f"
        noFront=${f#*OfflinePionLT_}
        echo $noFront
        low=${noFront:0:5}
        high=${noFront:6:5}
        echo "Searching for $RUNNUMBER between $low and $high"
        if [ $RUNNUMBER -le $high ] && [ $RUNNUMBER -ge $low ]; then
            echo "found ./OfflinePionLT_$low-$high.param copying"
            cp "./OfflinePionLT_$low-$high.param" $REPLAYPATH/DBASE/COIN/HodoCalib/OfflineCalib_$RUNNUMBER.param
            break
        fi
    done
fi
#echo "s/"$specL"hodo_TWcalib.param/Calibration\/"$specL"hodo_TWcalib_$RUNNUMBER.param/"
#sed -i "s/"$specL"hodo_TWcalib.param/Calibration\/"$specL"hodo_TWcalib_$RUNNUMBER.param/" $REPLAYPATH/DBASE/COIN/HodoCalib/OfflineCalib_$RUNNUMBER.param

# Back to the main directory
cd "$REPLAYPATH"                                
# Off we go again replaying
#echo "Starting 2nd Replay"
#eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/CALIBRATION/"$OPT"Hodo_Calib_Coin_Pt2.C($RUNNUMBER,$MAXEVENTS)\""
# Clean up the directories of our generated files
#mv "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/timeWalkHistos_"$RUNNUMBER".root" "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/Calibration_Plots/timeWalkHistos_"$RUNNUMBER".root"

cd "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/"
# Define the path to the second replay root file
ROOTFILE2="$REPLAYPATH/ROOTfiles/Calib/Hodo/"$OPT"_Hodo_Calib_Pt1_"$RUNNUMBER"_"$MAXEVENTS".root" # NH - have made an edit here to skip the TW step, if you need to do that you'll have to change back to using pt2
# Execute final script
echo "$ROOTFILE2"
root -l -q -b "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/fitHodoCalib.C(\"$ROOTFILE2\", $RUNNUMBER)" 
# Check our new file exists, if not exit, if yes, move it
if [ ! -f "$REPLAYPATH/PARAM/"$OPT"/HODO/"$specL"hodo_Vpcalib_$RUNNUMBER.param" ]; then
    echo ""$specL"hodo_Vpcalib_$RUNNUMBER.param not found, calibration script likely failed"
    exit 2
fi

mv "$REPLAYPATH/PARAM/"$OPT"/HODO/"$specL"hodo_Vpcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/"$OPT"/HODO/Calibration/"$specL"hodo_Vpcalib_$RUNNUMBER.param"

# Check our new file exists, if not exit, if yes, move it
if [ ! -f "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" ]; then
    echo "HodoCalibPlots_$RUNNUMBER.root not found, calibration script likely failed"
    exit 2
fi

mv "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/Calibration_Plots/HodoCalibPlots_$RUNNUMBER.root"

### Set in VpCalib to param path
sed -i "s/"$specL"hodo_Vpcalib.param/Calibration\/"$specL"hodo_Vpcalib_$RUNNUMBER.param/" $REPLAYPATH/DBASE/COIN/HodoCalib/OfflineCalib_$RUNNUMBER.param

cd "$REPLAYPATH"
eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/CALIBRATION/"$OPT"Hodo_Calib_Coin_Pt3.C($RUNNUMBER,$MAXEVENTS)\""
cd "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib"
root -l -q -b "$REPLAYPATH/CALIBRATION/"$spec"_hodo_calib/plotBeta.C($RUNNUMBER,$MAXEVENTS)"
exit 0
