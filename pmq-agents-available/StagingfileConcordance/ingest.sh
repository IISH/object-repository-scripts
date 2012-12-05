#!/bin/bash
#
# StagingFileIngestConcordance/ingest.sh
#
# Add Instruction
# Prepare a mets document
#
scripts=$scripts
source $scripts/shared/parameters.sh
fileSet=$fileSet
prefix=$(basename $fileSet)
log=$fileSet/$prefix.log
echo $(date)>$log
echo "Start preparing ingest...">>$log

cf=$fileSet/$prefix.concordanceValidWithPID.csv
if [ ! -f $cf ] ; then
    echo "Error... did not find $cf">>$log
    echo "Is the dataset validated ?">>$log
    exit -1
fi

source $scripts/pmq-agents-available/StagingfileConcordance/ingest.files.sh
source $scripts/pmq-agents-available/StagingfileConcordance/ingest.mets.sh
