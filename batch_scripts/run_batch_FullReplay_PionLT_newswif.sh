#! /bin/bash
#SBATCH --constraint=el9
#srun hostname

#
# Description:
# ======================================================
# Created:  Nathan Heinrich
# University of Regina, CA
# Date :2026
# ======================================================
#

echo "Running as ${USER}"

RunList=$1
MAXEVENTS=$2

if [[ -z "$1" ]]; then
    echo "I need a run list process!"
    echo "Please provide a run list as input"
    exit 2
fi
if [[ -z "$2" ]]; then
    echo "Only Run Number entered...I'll assume -1 events!" 
    MAXEVENTS=-1 
fi

UTILPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH"
ANASCRIPT="${UTILPATH}/Analysis_Scripts/FullReplay_PionLT_Batch_junaid.sh ${RUNTYPE}"

# 15/02/22 - SJDK - Added the swif2 workflow as a variable you can specify here
Workflow="LTSep_${USER}_${RunList}_${MAXEVENTS}" # Change this as desired
# Input run numbers, this just points to a file which is a list of run numbers, one number per line
inputFile="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/InputRunLists/PionLT_2021_2022/${RunList}"
#inputFile="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/InputRunLists/heep_runlist/${RunList}"

echo "making workflow ${Workflow}"
SitePath="/farm_out/${USER}/swif/${Workflow}"
mkdir SitePath
echo "setting output to ${SitePath}"
echo "swif2 cancel ${Workflow} -delete"
swif2 cancel ${Workflow} -delete
echo "swif2 create ${Workflow}"
swif2 create "$Workflow"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create workflow '$Workflow'"
    exit 1
fi

while true; do
    read -p "Do you wish to begin a new batch submission? (Please answer yes or no) " yn
    case $yn in
        [Yy]* )
            i=-1
            (
            ##Reads in input file##
            while IFS='' read -r line || [[ -n "$line" ]]; do
                echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                echo "Run number read from file: $line"
                echo ""
                ##Run number#
                runNum=$line
		if [[ $runNum -ge 10000 ]]; then
		    MSSstub='/mss/hallc/c-pionlt/raw/shms_all_%05d.dat'
		elif [[ $runNum -lt 10000 ]]; then
		    MSSstub='/mss/hallc/spring17/raw/coin_all_%05d.dat'
		fi
		##Output batch job file##
		batch="${USER}_${runNum}_FullReplay_${RUNTYPE}_Job.txt"
                tape_file=`printf $MSSstub $runNum`
		TapeFileSize=$(($(sed -n '4 s/^[^=]*= *//p' < $tape_file)/1000000000))
		if [[ $TapeFileSize == 0 ]];then
                    TapeFileSize=1
                fi
		echo "Raw .dat file is "$TapeFileSize" GB"
		if [[ $TapeFileSize -le 45 ]]; then
		    MEMORY="3000MB"
		elif [[ $TapeFileSize -ge 45 ]]; then
		    MEMORY="4000MB"
		fi
		echo "INPUT_FILES: ${tape_file}"
		if [ ! -f "/cache/hallc/c-pionlt/raw/shms_all_${runNum}.dat" ]; then
    		eval "jcache get /cache/hallc/c-pionlt/raw/shms_all_${runNum}.dat"
		fi
		
		#echo "TIME: 1" >> ${batch} 
		command="${ANASCRIPT} ${runNum} ${MAXEVENTS}"
        echo "${command}"
        echo "swif2 add-job ${Workflow} -name '${RunList}_${runNum}' -ram ${MEMORY} -stdout '${SitePath}/${runNum}.out' -stderr '${SitePath}/${runNum}.err' ${command}"
 		eval "swif2 add-job ${Workflow} -name ${RunList}_${runNum} -ram ${MEMORY} ${command}" # Swif2 job submission, updated!
                echo " "
		sleep 2
		rm ${batch}
                i=$(( $i + 1 ))
		if [ $i == $numlines ]; then
		    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		    echo " "
		    echo "###############################################################################################################"
		    echo "############################################ END OF JOB SUBMISSIONS ###########################################"
		    echo "###############################################################################################################"
		    echo " "
		fi
	    done < "$inputFile"
	    )
	    eval 'swif2 run ${Workflow}'
	    break;;
        [Nn]* ) 
	    exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
