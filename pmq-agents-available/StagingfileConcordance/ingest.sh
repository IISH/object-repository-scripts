#!/bin/bash
#
# StagingFileIngestConcordance/ingest.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document
#
# We offer the files in the current folder
# We move the mets into a separate folder
#
scripts=$scripts
validation=$validation
metsmaker=$metsmaker
ftpUser=$ftpUser
ftpPassword=$ftpPassword
source $scripts/shared/parameters.sh
fileSet=$fileSet
na=$na
prefix=$(basename $fileSet)
log=$fileSet/$prefix.log.txt
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