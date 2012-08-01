#!/bin/bash
#
# StagingFileIngestConcordance/startup.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document

scripts=$scripts
validation=$validation

source $scripts/shared/parameters.sh
fileSet=$fileSet
na=$na

prefix=$(basename $fileSet)
report=$fileSet/$prefix.report.txt
echo "Validation for $prefix started on $(date)" > $report
java -cp $validation org.objectrepository.validation.ConcordanceMain -fileSet ${fileSet%/*} w-prefix $prefix -na $na >> $report

exit $?
