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
archiveID=$archiveID
log=$log
cf=$cf
ftpScript=$ftpScript
fileSetMets=$fileSetMets

echo "Create METS">>$log
    java -cp $metsmaker org.iisg.visualmets.metsmaker.MetsMakerConsole -inputFile $cf -outputFolder $fileSet -proxy "http://hdl.handle.net/" -pidColumn PID -na $na>>$log
    mets=$fileSet/$archiveID.mets.csv
    echo "master,PID">$mets
    for file in $fileSet/*.xml
    do
        if [ -f $file ] ; then
            filename=$(basename "$file")
            pid=$na/${filename%.*}
            echo "/$archiveID.mets/$filename,$pid">>$mets
        fi
    done

echo "Move mets files to $fileSet.mets"
    mkdir -p $fileSetMets
    rm $fileSetMets/*
    mv $fileSet/$archiveID.*.xml $fileSetMets/

echo "Create instruction for METS">>$log
    php $scripts/pmq-agents-available/StagingfileConcordance/csv.php -f $mets -p PID -m master -access metadata -contentType text\xml
    if [ ! -f $fileSet/instruction.xml ] ; then
        echo "Instruction not found.">>$log
        exit -1
    fi
    mv $fileSet/instruction.xml $fileSetMets/

echo "Upload mets documents...">>$log
    cp $scripts/pmq-agents-available/StagingfileConcordance/lftp.conf $ftpScript
    echo "lftp -e open -u $lftpUser,$lftpPassword -p 21 stagingarea.objectrepository.org">>$ftpScript
    echo "mirror --reverse --continue --verbose --exclude-glob instruction.xml $fileSetMets $archiveID.mets">>$ftpScript
    echo "mv Jpeg .level1"
    echo "quit">>$ftpScript
    to=10
    for i in {1..$to}
    do
        echo "Ftp files... attempt $i of $to">>$log
        lftp -f $ftpScript>>$log
        rc=$?
        if [[ $rc == 0 ]] ; then
            break
        fi
    done
    rm $ftpScript


echo "Upload remaining instruction...">>$log
    cp $scripts/pmq-agents-available/StagingfileConcordance/lftp.conf $ftpScript
    echo "lftp -e open -u $lftpUser,$lftpPassword -p 21 stagingarea.objectrepository.org">>$ftpScript
    echo "put -c -O $archiveID.mets $fileSetMets/instruction.xml">>$ftpScript
    echo "quit">>$ftpScript
    lftp -f $ftpScript>>$log