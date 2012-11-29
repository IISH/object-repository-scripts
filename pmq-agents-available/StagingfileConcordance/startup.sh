#!/bin/bash
#
# StagingFileIngestConcordance/startup.sh
#
# Produce validation
# Add Instruction
# Prepare a mets document

scripts=$scripts
validation=$validation
metsmaker=$metsmaker

source $scripts/shared/parameters.sh
fileSet=$fileSet
na=$na

prefix=$(basename $fileSet)
report=$fileSet/$prefix.report.txt

echo "Validation for $prefix\nStarted on $(date)\n\n" > $report
java -Xms512m -Xmx512m -cp $validation org.objectrepository.validation.ConcordanceMain -fileSet ${fileSet%/*} -prefix $prefix -na $na >> $report

echo "Create instruction"
php csv.php -f $fileSet/concordanceValidWithPID.csv -p PID -m master -access restricted -contentType image\tiff

if [ -f $fileSet/concordanceValidWithPID.csv ] ; then
    echo "Create mets documents"
    java -cp $metsmaker org.iisg.visualmets.metsmaker.MetsMakerConsole -inputFile $fileSet/concordanceValidWithPID.csv -outputFolder $fileSet -proxy "http://hdl.handle.net/" -pidColumn PID -na $na
fi

exit $?