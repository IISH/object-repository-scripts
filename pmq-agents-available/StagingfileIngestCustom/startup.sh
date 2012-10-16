#!/bin/bash
#
# StagingFileIngestCustom/startup.sh
#
# Ingests any custom derivatives of the level1, level2 and level3 sort.

scripts=$scripts
fileSet=$fileSet
bucket="master"
source $scripts/shared/parameters.sh
db=$db
length=$length
md5=$md5
pid=$pid
access=$access
contentType=$contentType
label="$label"
l="$l"
action=$action

source $scripts/shared/primary.sh

if [ "$action" == "delete" ] ; then
    for b in "level1" "level2" "level3"
    do
        bucket=$b
        source $scripts/shared/delete.sh
    done
    exit $?
fi

continueOnSuccess="yes"
f=0
for level in 1 2 3
    do
         targetBucket="level$level"
         source $scripts/StagingfileIngestCustom/find.derivative.sh
    done

exit $f
