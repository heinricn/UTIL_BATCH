#! /bin/bash

#
# Description:
# ======================================================
# Created:  Muhammad Junaid
# University of Regina, CA
# Date :18-Dec-2023
# ======================================================
#

echo "Running as ${USER}"

RUNTYPE=$1
RunList=$2
MAXEVENTS=$3
if [[ -z "$1" || ! "$RUNTYPE" =~ Prod|Lumi|LumiCoin|HeePSingHMS|HeePSingSHMS|HeePCoin|pTRIG6 ]]; then # Check the 2nd argument was provided and that it's one of the valid options
    echo ""
    echo "I need a valid run type"
    while true; do
	echo ""
	read -p "Please type in a run type from - Prod - Lumi - LumiCoin - HeePSingHMS - HeePSingSHMS - HeePCoin - pTRIG6 - Case sensitive! - or press ctrl-c to exit : " RUNTYPE
	case $RUNTYPE in
	    '');; # If blank, prompt again
	    'Prod'|'Lumi'|'LumiCoin'|'HeePSingHMS'|'HeePSingSHMS'|'HeePCoin'|'pTRIG6') break;; # If a valid option, break the loop and continue
	esac
    done
fi
if [[ -z "$2" ]]; then
    echo "I need a run list process!"
    echo "Please provide a run list as input"
    exit 2
fi
if [[ $3 -eq "" ]]; then
    echo "Only Run Number entered...I'll assume -1 events!" 
    MAXEVENTS=-1 
fi

UTILPATH="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH"
ANASCRIPT="'${UTILPATH}/Analysis_Scripts/FullReplay_PionLT_Batch.sh' ${RUNTYPE}"

# 15/02/22 - SJDK - Added the swif2 workflow as a variable you can specify here
Workflow="LTSep_${USER}" # Change this as desired
# Input run numbers, this just points to a file which is a list of run numbers, one number per line
inputFile="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/InputRunLists/Production/${RunList}"

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
		tmp=tmp
                ##Finds number of lines of input file##
                numlines=$(eval "wc -l < ${inputFile}")
                echo "Job $(( $i + 2 ))/$(( $numlines +1 ))"
                echo "Running ${batch} for ${runNum}"
                cp /dev/null ${batch}
                ##Creation of batch script for submission##
		echo "MAIL: ${USER}@jlab.org" >> ${batch}
                echo "PROJECT: c-kaonlt" >> ${batch} # Or whatever your project is!
                echo "TRACK: analysis" >> ${batch}
                #echo "TRACK: debug" >> ${batch} ### Use for testing
                echo "JOBNAME: PionLT_${runNum}_${RUNTYPE}_Job" >> ${batch}
                # Request disk space depending upon raw file size
                echo "DISK_SPACE: "$(( $TapeFileSize * 2 ))" GB" >> ${batch}
		if [[ $TapeFileSize -le 45 ]]; then
		    echo "MEMORY: 3000 MB" >> ${batch}
		elif [[ $TapeFileSize -ge 45 ]]; then
		    echo "MEMORY: 6000 MB" >> ${batch}
		fi
		#echo "OS: centos7" >> ${batch}
                echo "CPU: 1" >> ${batch} ### hcana single core, setting CPU higher will lower priority!
		echo "INPUT_FILES: ${tape_file}" >> ${batch}
		#echo "TIME: 1" >> ${batch} 
		echo "COMMAND:${ANASCRIPT} ${runNum} ${MAXEVENTS}" >> ${batch}
                echo "Submitting batch"
 		eval "swif2 add-jsub ${Workflow} -script ${batch} 2>/dev/null" # Swif2 job submission, uses old jsub scripts
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
