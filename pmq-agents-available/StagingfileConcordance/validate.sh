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
report=$fileSet/$prefix.report.txt
log=$fileSet/$prefix.log
cf=$fileSet/$prefix.concordanceValidWithPID.csv
na=$na
mailTo=$mailTo

echo $(date)>$log
echo "Start validation">>$log

echo "Validation for $prefix\nStarted on $(date)\n\n" > $report
java -Xms512m -Xmx512m -cp $validation org.objectrepository.validation.ConcordanceMain -fileSet ${fileSet%/*} -prefix $prefix -na $na >> $report
mv $fileSet/concordanceValidWithPID.csv $cf
if [ ! -f $cf ] ; then
    echo "Unable to find $cf">>$log
    exit -1
fi

echo "Ignore warnings on Thumbs.db" >> $report

echo $(date)>>$log
echo "Done validate.">>$log

exit $?
