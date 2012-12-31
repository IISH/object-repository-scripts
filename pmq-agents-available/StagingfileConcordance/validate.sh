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

echo "md5 check for $prefix\nStarted on $(date)\n\n" >> $report
checksumFrom=$fileSet/Checksum
checksumTo=$fileSet/.Checksum
mv $fileSet/$checksumFrom $checksumTo
if [ ! -d $checksumTo ] ; then
    echo "Unable to find $checksumFrom or $checksumTo ">>$log
    exit -1
fi

checksumReport=$fileSet/$prefix.checksum.txt
:>$checksumReport
for file in $checksumTo/*.csv
do
    filename=$(basename "$file")
    arr=(${filename//-/ })
    folder=${arr[0]}
    while read line
    do
        arr=(${line//;/ })
        filename=$fileSet/Tiff/$folder/${arr[0]}
        if [ -f $filename ] ; then
            md5=${arr[1],,}
            md5=${md5:0:32}
            md5file=$checksumTo/$filename.md5
            if [ ! -f $md5file ] ; then
                md5sum $filename > $checksumTo/$filename.md5
            fi
            md5Check=$(cat $md5file | cut -d ' ' -f 1)
            if [ "$md5" == "$md5Check" ] ; then
                echo "Checksom ok: $md5Check $filename">>$log
            else
                echo "Warning: factory checksum $md5 does not match calculated $md5Check for $filename">>$checksumReport
            fi
        else
            echo "Warning: file not found: $filename">>$checksumReport
        fi
    done <$file
done

length=$(stat -c%s "$checksumReport")
if [ $length != 0 ] ; then
    echo "Error: not all md5 checksums match. See report $checksumReport"
fi

echo $(date)>>$log
echo "Done validate.">>$log

exit $?