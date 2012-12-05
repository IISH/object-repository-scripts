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
prefix=$(basename $fileSet)
report=$fileSet/$prefix.report.txt
log=$fileSet/$prefix.log.txt

echo $(date)>$log
echo "Start validation">>$log


source $scripts/shared/parameters.sh
fileSet=$fileSet
na=$na

echo "Validation for $prefix\nStarted on $(date)\n\n" > $report
java -Xms512m -Xmx512m -cp $validation org.objectrepository.validation.ConcordanceMain -fileSet ${fileSet%/*} -prefix $prefix -na $na >> $report
mv $fileSet/concordanceValidWithPID.csv $fileSet/$prefix.concordanceValidWithPID.csv

echo $(date)>>$log
echo "Done validate.">>$log

exit $?