#!/bin/bash

### Stephen Kay --- University of Regina --- 12/11/19 ###
### Script for running (via batch or otherwise) the hodoscope calibration, this one script does all of the relevant steps for the calibration proces
### Note that the second part also has an additional bit where it checks for a database file based upon the run number

RUNNUMBER=$1
### Check you've provided the first argument  
if [[ $1 -eq "" ]]; then
    echo "I need a Run Number!"
    echo "Please provide a run number as input"
    exit 2
fi
### Check if a Second argument was provided, if not assume -1, if yes, this is max events
if [[ $2 -eq "" ]]; then
    MAXEVENTS=-1
else
    MAXEVENTS=$2
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
	source /site/12gev_phys/softenv.sh 2.3
        source /apps/root/6.18.04/setroot_CUE.bash #set ROOT Version
    fi
    cd "/group/c-kaonlt/hcana/"
    source "/group/c-kaonlt/hcana/setup.sh"
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh"
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    REPLAYPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt"
    source /site/12gev_phys/softenv.sh 2.3
    cd "/group/c-kaonlt/hcana/"
    source "/group/c-kaonlt/hcana/setup.sh" 
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh" 
elif [[ "${HOSTNAME}" = *"cdaq"* ]]; then
    REPLAYPATH="/home/cdaq/hallc-online/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"phys.uregina.ca"* ]]; then
    REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_lt"
fi
cd $REPLAYPATH

### Check the extra folders you'll need exist, if they don't then make them
if [ ! -d "$REPLAYPATH/DBASE/COIN/HodoCalib" ]; then
    mkdir "$REPLAYPATH/DBASE/COIN/HodoCalib"
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

echo "Running First replay!"
eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/CALIBRATION/Hodo_Calib_Coin_Pt1.C($RUNNUMBER,$MAXEVENTS)\""
ROOTFILE="$REPLAYPATH/ROOTfiles/Calib/Hodo/Hodo_Calib_Pt1_"$RUNNUMBER"_"$MAXEVENTS".root" 

sleep 5

#run analysis for both detectors
echo "********************************"
echo "Running HMS TimeWalk Calibration"
echo "********************************" 
cd "$REPLAYPATH/CALIBRATION/hms_hodo_calib/"
root -l -q -b "$REPLAYPATH/CALIBRATION/hms_hodo_calib/timeWalkHistos.C(\"$ROOTFILE\", $RUNNUMBER, \"coin\")"
sleep 5
root -l -q -b "$REPLAYPATH/CALIBRATION/hms_hodo_calib/timeWalkCalib.C($RUNNUMBER)"
sleep 1
echo "*********************************" 
echo "Running SHMS TimeWalk Calibration"
echo "*********************************" 
cd "$REPLAYPATH/CALIBRATION/shms_hodo_calib/"
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/timeWalkHistos.C(\"$ROOTFILE\", $RUNNUMBER, \"coin\")"
sleep 5
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/timeWalkCalib.C($RUNNUMBER)"

# After executing first two root scripts, should have a new .param files so long as scripts ran ok, IF NOT THEN EXIT
if [ ! -f "$REPLAYPATH/PARAM/HMS/HODO/hhodo_TWcalib_$RUNNUMBER.param" ]; then
    echo "hhodo_TWCalib_$RUNNUMBER.param not found, calibration script likely failed"
    exit 2
fi
if [ ! -f "$REPLAYPATH/PARAM/SHMS/HODO/phodo_TWcalib_$RUNNUMBER.param" ]; then
    echo "phodo_TWCalib_$RUNNUMBER.param not found, calibration script likely failed"
    exit 2
fi


# Need to find the DBASE file used in the previous replay, do this from the replay script used
REPLAYSCRIPT1="${REPLAYPATH}/SCRIPTS/COIN/CALIBRATION/Hodo_Calib_Coin_Pt1.C"
while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ "//" ]]; then continue;
    elif [[ $line =~ "gHcParms->AddString(\"g_ctp_database_filename\"," ]]; then
	tmpstring=$(echo $line| cut -d "," -f2) # This is the path to the DBase file but with some junk in the string
	tmpstring2=$(echo $tmpstring | sed 's/[");]//g') # Sed command to strip junk (", ) or ; ) from the string
	BASE_DBASEFILE="${REPLAYPATH}/${tmpstring2}"
    fi
done < "$REPLAYSCRIPT1" 

# Need to find the param file used in the previous replay, do this from provided runnumber and the database file
# This could probably be simplified slightly, but basically it finds the right "block" and sets a flag to pick up the NEXT param file listed
TestingVar=$((0))
while IFS='' read -r line || [[ -n "$line" ]]; do
    # If the line in the file is blank, contains a hash or has g_ctp in it, skip it, only leaves the lines which contain the run numbe ranges
    if [ -z "$line" ] ; then continue;
    elif [[ $line =~ "#" ]]; then continue;
    elif [[ $line =~ "g_ctp_kin" ]]; then continue;
    elif [[ $line != *"g_ctp_par"* ]]; then #If line is NOT the one specifying the param file, then get the run numbers
	# Starting run number is just the field before the - delimiter (f1), ending run number is the one after (f2)
	# -d specifies the delimiter which is the term in speech marks
	RunStart=$(echo $line| cut -d "-" -f1)
	RunEnd=$(echo $line| cut -d "-" -f2)
	if [ "$RUNNUMBER" -ge "$RunStart" -a "$RUNNUMBER" -le "$RunEnd" ]; then
	    TestingVar=$((1)) # If run number in range, set testing var to 1
	else TestingVar=$((0)) # If not in range, set var to 0
	fi
    elif [[ $line =~ "g_ctp_par" ]]; then
	if [ $TestingVar == 1 ]; then
	    tmpstring3=$(echo $line| cut -d "=" -f2) # tmpstrings could almost certainly be combined into one expr
	    BASE_PARAMFILE=$(echo $tmpstring3 | sed 's/["]//g')
	    BASE_PARAMFILE_PATH="${REPLAYPATH}/${BASE_PARAMFILE}"
	else continue
	fi
    fi
done < "$BASE_DBASEFILE"

# Now have base DBASE and PARAM files, copy these to a new directory and edit them with newly generated param files
# Check files exist first, if they do, copy them and proceed
if [[ ! -f "$BASE_DBASEFILE" || ! -f "$BASE_PARAMFILE_PATH" ]]; then
    echo "Base DBASE or param file not found, check -"
    echo "$BASE_DBASEFILE"
    echo "and"
    echo "$BASE_PARAMFILE_PATH"
    echo "exist. Modify script accordingly."
    exit 3
fi

echo "Copying $BASE_DBASEFILE and $BASE_PARAMFILE_PATH to HodoCalib"
cp "$BASE_DBASEFILE" "${REPLAYPATH}/DBASE/COIN/HodoCalib/standard_${RUNNUMBER}.database"
cp "$BASE_PARAMFILE_PATH" "${REPLAYPATH}/DBASE/COIN/HodoCalib/general_${RUNNUMBER}.param"

# Switch out the param file called in the dbase file
# Sed command looks a bit different, need to use different quote/delimiters as variable uses / and so on
sed -i 's|'"$BASE_PARAMFILE"'|'"DBASE/COIN/HodoCalib/general_$RUNNUMBER.param"'|' "${REPLAYPATH}/DBASE/COIN/HodoCalib/standard_${RUNNUMBER}.database"

# Switch out the relevant files in the param file
sed -i "s/hhodo_TWcalib.*/hhodo_TWcalib_${RUNNUMBER}.param\"/" "${REPLAYPATH}/DBASE/COIN/HodoCalib/general_${RUNNUMBER}.param"
sed -i "s/phodo_TWcalib.*/phodo_TWcalib_${RUNNUMBER}.param\"/" "${REPLAYPATH}/DBASE/COIN/HodoCalib/general_${RUNNUMBER}.param"


sleep 5 #This should stop it from failing due to opening files before they're closed

# Back to the main directory
cd "$REPLAYPATH"                                
# Off we go again replaying
echo "********************************" 
echo "    Running second replay!"
echo "********************************" 
eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/CALIBRATION/Hodo_Calib_Coin_Pt2.C($RUNNUMBER,$MAXEVENTS)\""

# Clean up the directories of our generated files
mv "$REPLAYPATH/CALIBRATION/hms_hodo_calib/timeWalkHistos_"$RUNNUMBER".root" "$REPLAYPATH/CALIBRATION/hms_hodo_calib/Calibration_Plots/timeWalkHistos_"$RUNNUMBER".root"
mv "$REPLAYPATH/CALIBRATION/hms_hodo_calib/timeWalkCalib_"$RUNNUMBER".root" "$REPLAYPATH/CALIBRATION/hms_hodo_calib/Calibration_Plots/timeWalkCalib_"$RUNNUMBER".root"
mv "$REPLAYPATH/CALIBRATION/shms_hodo_calib/timeWalkHistos_"$RUNNUMBER".root" "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots/timeWalkHistos_"$RUNNUMBER".root"
mv "$REPLAYPATH/CALIBRATION/shms_hodo_calib/timeWalkCalib_"$RUNNUMBER".root" "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots/timeWalkCalib_"$RUNNUMBER".root"

sleep 5

# Define the path to the second replay root file
ROOTFILE2="$REPLAYPATH/ROOTfiles/Calib/Hodo/Hodo_Calib_Pt2_"$RUNNUMBER"_"$MAXEVENTS".root"

# Execute final scripts
echo "********************************" 
echo "    Running HMS Hodo Fits"
echo "********************************" 
cd "$REPLAYPATH/CALIBRATION/hms_hodo_calib/"
root -l -q -b "$REPLAYPATH/CALIBRATION/hms_hodo_calib/fitHodoCalib.C(\"$ROOTFILE2\", $RUNNUMBER)" 

echo "********************************" 
echo "    Running SHMS Hodo Fits"
echo "********************************" 
cd "$REPLAYPATH/CALIBRATION/shms_hodo_calib/"
root -l -q -b "$REPLAYPATH/CALIBRATION/shms_hodo_calib/fitHodoCalib.C(\"$ROOTFILE2\", $RUNNUMBER)" 

# Check our new files exist, if not exit, if yes, move it
if [ ! -f "$REPLAYPATH/PARAM/HMS/HODO/hhodo_Vpcalib_$RUNNUMBER.param" ]; then
    echo "hhodo_Vpcalib_$RUNNUMBER.param not found, calibration script likely failed"
    exit 2
fi
if [ ! -f "$REPLAYPATH/PARAM/SHMS/HODO/phodo_Vpcalib_$RUNNUMBER.param" ]; then
    echo "phodo_Vpcalib_$RUNNUMBER.param not found, calibration script likely failed"
    exit 2
fi



# Check our new files exists, if not exit, if yes, move it
if [ ! -f "$REPLAYPATH/CALIBRATION/hms_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" ]; then
    echo "HodoCalibPlots_$RUNNUMBER.root not found, calibration script likely failed"
    exit 2
fi
if [ ! -f "$REPLAYPATH/CALIBRATION/shms_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" ]; then
    echo "HodoCalibPlots_$RUNNUMBER.root not found, calibration script likely failed"
    exit 2
fi

mv "$REPLAYPATH/CALIBRATION/hms_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" "$REPLAYPATH/CALIBRATION/hms_hodo_calib/Calibration_Plots/HodoCalibPlots_$RUNNUMBER.root"
mv "$REPLAYPATH/CALIBRATION/shms_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots/HodoCalibPlots_$RUNNUMBER.root"

### Now we set up the third replay by editing our general.param file
cd "$REPLAYPATH/DBASE/COIN"
# Switch out the relevant files in the param files
sed -i "s/hhodo_Vpcalib.*/hhodo_Vpcalib_${RUNNUMBER}.param\"/" "${REPLAYPATH}/DBASE/COIN/HodoCalib/general_${RUNNUMBER}.param"
sed -i "s/phodo_Vpcalib.*/phodo_Vpcalib_${RUNNUMBER}.param\"/" "${REPLAYPATH}/DBASE/COIN/HodoCalib/general_${RUNNUMBER}.param"


sleep 1

cd "$REPLAYPATH"
echo "********************************" 
echo "     Running Final replay!"
echo "********************************" 
eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/COIN/CALIBRATION/Hodo_Calib_Coin_Pt3.C($RUNNUMBER,$MAXEVENTS)\""

# Finished so put our new param files away
mv "$REPLAYPATH/PARAM/HMS/HODO/hhodo_TWcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/HMS/HODO/Calibration/hhodo_TWcalib_$RUNNUMBER.param"
mv "$REPLAYPATH/PARAM/HMS/HODO/hhodo_Vpcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/HMS/HODO/Calibration/hhodo_Vpcalib_$RUNNUMBER.param"

mv "$REPLAYPATH/PARAM/SHMS/HODO/phodo_TWcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/SHMS/HODO/Calibration/phodo_TWcalib_$RUNNUMBER.param"
mv "$REPLAYPATH/PARAM/SHMS/HODO/phodo_Vpcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/SHMS/HODO/Calibration/phodo_Vpcalib_$RUNNUMBER.param"

exit 0



