#!/bin/bash
#
# StagingFileIngestConcordance/ingest.files.sh
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
fileSet=$fileSet
na=$na
prefix=$prefix
log=$log
cf=$cf

echo "Upload files...">>$log
    lftp -f /opt/lftp.txt $ftpUser $ftpPassword $fileSet $prefix.files

echo "Create instruction for our files">>$log
    php csv.php -f $cf -p PID -m master -access restricted -contentType image\tiff
    if [ ! -f $fileSet/instruction.xml ] ; then
        echo "Instruction not found.">>$log
        exit -1
    fi

echo "Upload remaining instruction...">>$log
    lftp -f /opt/lftp.txt $ftpUser $ftpPassword $fileSet $prefix.files

echo $(date)>>$log
echo "Done files update.">>$log