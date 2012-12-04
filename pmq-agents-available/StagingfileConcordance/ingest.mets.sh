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
fileSet=$fileSet.mets
na=$na
prefix=$prefix
log=$log
cf=$cf

echo "Create METS">>$log
    mkdir -p $fileSet
    java -cp $metsmaker org.iisg.visualmets.metsmaker.MetsMakerConsole -inputFile $cf -outputFolder $fileSet -proxy "http://hdl.handle.net/" -pidColumn PID -na $na
    mets=$fileSet/$prefix.mets.csv
    echo "master,PID">$mets
    for file in $fileSet/*.xml
    do
        filename=$(basename "$file")
        pid=$na/${filename%.*}
        echo "/$prefix/$filename,$pid">>$mets
    done

echo "Upload mets documents...">>$log
    lftp -f /opt/lftp.txt $ftpUser $ftpPassword $fileSet $prefix.mets

echo "Create instruction for METS">>$log
    php $scripts/pmq-agents-available/StagingfileConcordance/csv.php -f $mets -p PID -m master -access metadata -contentType text\xml
    if [ ! -f $fileSet/instruction.xml ] ; then
        echo "Instruction not found.">>$log
        exit -1
    fi

echo "Upload remaining instruction...">>$log
    lftp -f /opt/lftp.txt $ftpUser $ftpPassword $fileSet $prefix.mets
