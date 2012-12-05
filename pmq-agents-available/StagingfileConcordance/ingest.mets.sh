#!/bin/bash
#
# StagingFileIngestConcordance/ingest.files.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document
#
scripts=$scripts
validation=$validation
metsmaker=$metsmaker
lftpUser=$lftpUser
lftpPassword=$lftpPassword
fileSet=$fileSet
na=$na
prefix=$prefix
log=$log
cf=$cf
ftpScript=$fileSet/$prefix.lftp

echo "Create METS">>$log
    mkdir -p $fileSet
    java -cp $metsmaker org.iisg.visualmets.metsmaker.MetsMakerConsole -inputFile $cf -outputFolder $fileSet -proxy "http://hdl.handle.net/" -pidColumn PID -na $na>>$log
    mets=$fileSet/$prefix.mets.csv
    echo "master,PID">$mets
    for file in $fileSet/*.xml
    do
        filename=$(basename "$file")
        pid=$na/${filename%.*}
        echo "/$prefix/$filename,$pid">>$mets
    done

echo "Upload mets documents...">>$log
    cp $scripts/pmq-agents-available/StagingfileConcordance/lftp.conf $ftpScript
    echo "lftp -e open -u $lftpUser,$lftpPassword -p 21 stagingarea.objectrepository.org">>$ftpScript
    echo "mirror --reverse --continue --verbose --exclude-glob $prefix.* $fileSet $prefix.mets">>$ftpScript
    echo "quit">>$ftpScript
    lftp -f $ftpScript>>$log

echo "Create instruction for METS">>$log
    php $scripts/pmq-agents-available/StagingfileConcordance/csv.php -f $mets -p PID -m master -access metadata -contentType text\xml
    if [ ! -f $fileSet/instruction.xml ] ; then
        echo "Instruction not found.">>$log
        exit -1
    fi

echo "Upload remaining instruction...">>$log
    cp $scripts/pmq-agents-available/StagingfileConcordance/lftp.conf $ftpScript
    echo "lftp -e open -u $lftpUser,$lftpPassword -p 21 stagingarea.objectrepository.org">>$ftpScript
    echo "put -c -O $prefix.files $fileSet/instruction.xml">>$ftpScript
    echo "quit">>$ftpScript
    lftp -f $ftpScript>>$log