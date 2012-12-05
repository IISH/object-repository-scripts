#!/bin/bash
#
# StagingFileIngestConcordance/validate.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document

scripts=$scripts
validation=$validation
metsmaker=$metsmaker
fileSet=$fileSet
source $scripts/shared/parameters.sh
prefix=$(basename $fileSet)
report=$fileSet/report.txt
log=$fileSet/$prefix.log

echo $(date)>$log
echo "Start validation">>$log

fileSet=$fileSet
na=$na

echo "Validation for $prefix\nStarted on $(date)\n\n" > $report
java -Xms512m -Xmx512m -cp $validation org.objectrepository.validation.ConcordanceMain -fileSet ${fileSet%/*} -prefix $prefix -na $na >> $report
if [ ! -f $fileSet/concordanceValidWithPID.csv ] ; then
    echo "Unable to find $fileSet/concordanceValidWithPID.csv"
    exit -1
fi

echo $(date)>>$log
echo "Done validate.">>$log

exit $?