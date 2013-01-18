#!/bin/bash

scripts=$scripts
source $scripts/shared/parameters.sh
fileSet=$fileSet
prefix=$(basename $fileSet)
report=$fileSet/$prefix.report.checksum.txt
log=$fileSet/$prefix.log

# Remove DOS \r
file=$fileSet/checksum.md5
if [ ! -f $file ] ; then
    echo "File not found: $file">$report
    echo "No checksum file found at $file">$log
    exit -1
fi

backup=$fileSet/.checksum.md5
if [ ! -f $backup ] ; then
    cp $file $backup
fi
tr -d '\r' < $file > /tmp/t
mv /tmp/t $file
cd $fileSet

md5sum --check $file > $report