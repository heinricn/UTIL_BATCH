#! /bin/bash                                                                                                                                                                                                      

##### A batch submission script for doing Hodoscope Calibration Plots
##### By Nathan Heinrich

echo "Running as ${USER}"

##Input run numbers##
INPUTFILE=$1   

echo $INPUTFILE

if [ -z "$INPUTFILE" ]; then
	echo "Please input a runlist file from UTIL_BATCH/InputRunLists/"
	echo "Exiting"
	exit 2
fi

##Output history file##                                                                                                                                                                                           
historyfile=hist.$( date "+%Y-%m-%d_%H-%M-%S" ).log

##Output batch script##                                                                                                                                                                                           
batch="${USER}_Job.txt"

## Setting Up Batch Submission##
echo "PROJECT: c-kaonlt" >> ${batch}
echo "TRACK: analysis" >> ${batch}
echo "JOBNAME: KaonLT_HodoCalib_SummaryPlots" >> ${batch}
echo "DISK_SPACE: 20 GB" >> ${batch}
echo "MEMORY: 4000 MB" >> ${batch}
#echo "OS: centos7" >> ${batch}
echo "CPU: 1" >> ${batch} ### hcana single core, setting CPU higher will lower priority!                                                                                                          
echo "INPUT_FILES: ${tape_file}" >> ${batch}
echo "COMMAND:/group/c-kaonlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/Analysis_Scripts/HodoPlots_Batch.sh ${INPUTFILE}" >> ${batch} 
echo "MAIL: ${USER}@jlab.org" >> ${batch}

echo "Submitting batch"
eval "jsub ${batch} 2>/dev/nul"
echo " "

