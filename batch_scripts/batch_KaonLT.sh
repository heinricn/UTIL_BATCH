#! /bin/bash

#
# Description:
# ================================================================
# Time-stamp: "2023-08-06 11:47:36 trottar"
# ================================================================
#
# Author:  Richard L. Trotta III <trotta@cua.edu>
#
# Copyright (c) trottar
#

### Stephen Kay, University of Regina
### 03/03/21
### stephen.kay@uregina.ca
### A batch submission script based on an earlier version by Richard Trotta, Catholic University of America                       
##### Modify required resources as needed!

echo 
echo
echo
echo "Running as ${USER}"

# Flag definitions (flags: h, a)
while getopts 'ha' flag; do
    case "${flag}" in
        h) 
        echo "--------------------------------------------------------------"
        echo "./batch_KaonLT.sh -{flags} {variable arguments, see help}"
	echo
        echo "Description: Runs scripts for batch submission"
        echo "--------------------------------------------------------------"
        echo
        echo "The following flags can be called for the heep analysis..."
	echo "    If no flags called arguments are..."
	echo "        RUNTYPE=arg1, TARGET=arg2, RunList=arg3, MAXEVENTS=arg4"
        echo "    -h, help"
        echo "    -a, Runs LTSep analysis"
	echo "        EPSILON=arg1, PHIVAL=arg2, Q2=arg3, W=arg4, target=arg5"
	echo
	echo " Avaliable Kinematics..."	
	echo "                      Q2=5p5, W=3p02"
	echo "                      Q2=4p4, W=2p74"
	echo "                      Q2=3p0, W=3p14"
	echo "                      Q2=3p0, W=2p32"
	echo "                      Q2=2p1, W=2p95"
	echo "                      Q2=0p5, W=2p40"
        exit 0
        ;;
	a) a_flag='true' ;;
        *) print_usage
        exit 1 ;;
    esac
done

UTILPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH"

echo $a_flag

if [[ $a_flag = "true" ]]; then
    EPSILON=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    PHIVAL=$(echo "$3" | tr '[:upper:]' '[:lower:]')
    Q2=$4
    W=$5
    TARGET=$(echo "$6" | tr '[:upper:]' '[:lower:]')
    RunList=$7

    if [[ -z "$2" || ! "$EPSILON" =~ high|low ]]; then # Check the 1st argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid epsilon..."
	while true; do
	    echo ""
	    read -p "Press ctrl-c to exit : " EPSILON
	    case $EPSILON in
		'');; # If blank, prompt again
		'high'|'low') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$3" || ! "$PHIVAL" =~ right|left|center ]]; then # Check the 1st argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid phi value..."
	while true; do
	    echo ""
	    read -p "Press ctrl-c to exit : " PHIVAL
	    case $PHIVAL in
		'');; # If blank, prompt again
		'right'|'left'|'center') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$4" || ! "$Q2" =~ 5p5|4p4|3p0|2p1|0p5 ]]; then # Check the 2nd argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid Q2..."
	while true; do
	    echo ""
	    read -p "Q2 must be one of - [5p5 - 4p4 - 3p0 - 2p1 - 0p5] - or press ctrl-c to exit : " Q2
	    case $Q2 in
		'');; # If blank, prompt again
		'5p5'|'4p4'|'3p0'|'2p1'|'0p5') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$5" || ! "$W" =~ 3p02|2p74|3p14|2p32|2p95|2p40 ]]; then # Check the 3rd argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid W..."
	while true; do
	    echo ""
	    read -p "W must be one of - [3p02 - 2p74 - 3p14 - 2p32 - 2p95 - 2p40] - or press ctrl-c to exit : " W
	    case $W in
		'');; # If blank, prompt again
		'3p02'|'2p74'|'3p14'|'2p32'|'2p95'|'2p40') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$6" || ! "$TARGET" =~ lh2|dummy ]]; then # Check the 3rd argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid target type..."
	while true; do
	    echo ""
	    read -p "Target type must be one of - [lh2 - dummy] - or press ctrl-c to exit : " TARGET
	    case $TARGET in
		'');; # If blank, prompt again
		'lh2'|'dummy') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$7" ]]; then
	echo "I need a run list process!"
	echo "Please provide a run list as input"
	exit 2
    fi

    ANASCRIPT="'${UTILPATH}/Analysis_Scripts/KaonLT.sh' -a ${EPSILON} ${PHIVAL} ${Q2} ${W} ${TARGET}"

else
    RUNTYPE=$1
    TARGET=$2
    RunList=$3
    MAXEVENTS=$4
    if [[ -z "$1" || ! "$RUNTYPE" =~ Prod|Lumi|HeePSing|HeePCoin|fADC|Optics|HGCer ]]; then # Check the 2nd argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid run type"
	while true; do
	    echo ""
	    read -p "Please type in a run type from - Prod - Lumi - HeePSing - HeePCoin - fADC - Optics - HGCer - Case sensitive! - or press ctrl-c to exit : " RUNTYPE
	    case $RUNTYPE in
		'');; # If blank, prompt again
		'Prod'|'Lumi'|'HeePSing'|'HeePCoin'|'Optics'|'fADC'|'HGCer') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$2" || ! "$TARGET" =~ LH2|LD2|Dummy10cm|Carbon0p5|AuFoil|Optics1|Optics2|CarbonHole ]]; then # Check the 3rd argument was provided and that it's one of the valid options
	echo ""
	echo "I need a valid target"
	while true; do	
	    echo ""
	    read -p "Please type in a target from - LH2 - LD2 - Dummy10cm - Carbon0p5 - AuFoil - Optics1 - Optics2 - CarbonHole - Case sensitive! - or press ctrl-c to exit : " TARGET
	    case $TARGET in
		'');; # If blank, prompt again
		'LH2'|'LD2'|'Dummy10cm'|'Carbon0p5'|'AuFoil'|'Optics1'|'Optics2'|'CarbonHole') break;; # If a valid option, break the loop and continue
	    esac
	done
    fi
    if [[ -z "$3" ]]; then
	echo "I need a run list process!"
	echo "Please provide a run list as input"
	exit 2
    fi
    if [[ $4 -eq "" ]]; then
	echo "Only Run Number entered...I'll assume -1 events!" 
	MAXEVENTS=-1 
    fi

    ANASCRIPT="'${UTILPATH}/Analysis_Scripts/KaonLT.sh' ${RUNTYPE} ${TARGET}"

fi

# 15/02/22 - SJDK - Added the swif2 workflow as a variable you can specify here
Workflow="LTSep_${USER}" # Change this as desired
# Input run numbers, this just points to a file which is a list of run numbers, one number per line
inputFile="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/InputRunLists/KaonLT_2018_2019/${RunList}"

while true; do

    if [[ $a_flag = "true" ]]; then
	yn="Y"  # Set the variable directly to "Y" to bypass the prompt
    else
	read -p "Do you wish to begin a new batch submission? (Please answer yes or no) " yn
    fi

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
		    MSSstub='/mss/hallc/c-kaonlt/raw/shms_all_%05d.dat'
		elif [[ $runNum -lt 10000 ]]; then
		    MSSstub='/mss/hallc/spring17/raw/coin_all_%05d.dat'
		fi
		##Output batch job file##
		if [[ $a_flag = 'true' ]]; then
		    batch="${USER}_${runNum}_FullReplay_LTSep_Job.txt"
		else
		    batch="${USER}_${runNum}_FullReplay_${RUNTYPE}_Job.txt"
		fi
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
		if [[ $a_flag = 'true' ]]; then
		    echo "JOBNAME: KaonLT_LTSep_${runNum}" >> ${batch}
		else
		    echo "JOBNAME: KaonLT_${RUNTYPE}_${runNum}" >> ${batch}
		fi
		# Request disk space depending upon raw file size
		#echo "DISK_SPACE: "$(( $TapeFileSize * 2 ))" GB" >> ${batch}
		echo "DISK_SPACE: 50 GB" >> ${batch}
		#if [[ $TapeFileSize -le 45 ]]; then
		#    echo "MEMORY: 3000 MB" >> ${batch}
		#elif [[ $TapeFileSize -ge 45 ]]; then
		#    echo "MEMORY: 4000 MB" >> ${batch}
		#fi
		echo "MEMORY: 10000 MB" >> ${batch}
		#echo "OS: centos7" >> ${batch}
		echo "CPU: 1" >> ${batch} ### hcana single core, setting CPU higher will lower priority!
		echo "INPUT_FILES: ${tape_file}" >> ${batch}
		#echo "TIME: 1" >> ${batch}
		if [[ $a_flag = 'true' ]]; then
		    echo "COMMAND:${ANASCRIPT} ${runNum}" >> ${batch}
		else
		    echo "COMMAND:${ANASCRIPT} ${runNum} ${MAXEVENTS}" >> ${batch}
		fi
		echo "Submitting batch"
		eval "swif2 add-jsub ${Workflow} -script ${batch} 2>/dev/null" # Swif2 job submission, uses old jsub scripts
		eval "swif2 notify ${Workflow} -when done -email ${USER}@jlab.org" # Send email notification when jobs finish
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

