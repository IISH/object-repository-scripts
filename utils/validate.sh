#!/bin/bash
#
# validate.sh pid -db DB -pid PID -md5 MD5
#
# Checks out the file and recalculates the md5
#

scripts=$scripts
source $scripts/shared/parameters.sh
db=$db
sourceBucket=master
pid=$pid
md5=$md5
l=/derivative/cache/$md5
source $scripts/shared/get.sh

if [ -f $l ] ; then
    md5check=$(md5sum $l)
    rm $l
    echo "$pid $md5 $md5check"
else
    echo "$pid $md5 NA NA"
fi