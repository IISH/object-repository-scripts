#!/bin/bash
#
# StagingFileIngestConcordance/ingest.files.sh
#
# Produce validation
# Add Instruction
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
ftpScript=$ftpScript
fileSetMets=$fileSetMets


echo "Upload files...">>$log
    mv $fileSet/Jpeg $fileSet/.level1
    cp $scripts/pmq-agents-available/StagingfileConcordance/lftp.conf $ftpScript
    echo "lftp -e open -u $lftpUser,$lftpPassword -p 21 stagingarea.objectrepository.org">>$ftpScript
    echo "mirror --reverse --continue --verbose --exclude-glob $prefix.* $fileSet $prefix">>$ftpScript
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
    mv $fileSet/.level1 $fileSet/Jpeg
    rm $ftpScript

echo "Create instruction for our files">>$log
    php $scripts/pmq-agents-available/StagingfileConcordance/csv.php -f $cf -p PID -m master -access restricted -contentType image\tiff
    if [ ! -f $fileSet/instruction.xml ] ; then
        echo "Instruction not found.">>$log
        exit -1
    fi

echo "Upload remaining instruction...">>$log
    cp $scripts/pmq-agents-available/StagingfileConcordance/lftp.conf $ftpScript
    echo "lftp -e open -u $lftpUser,$lftpPassword -p 21 stagingarea.objectrepository.org">>$ftpScript
    echo "put -c -O $prefix $fileSet/instruction.xml">>$ftpScript
    echo "quit">>$ftpScript
    lftp -f $ftpScript>>$log
    rm $ftpScript

echo $(date)>>$log
echo "Done files update.">>$log

rm $fileSet/instruction.xml