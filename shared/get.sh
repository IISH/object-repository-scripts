#!/bin/bash
#
# Reads a file from the database
#
scripts=$scripts
orfiles=$orfiles
host=$host
bucket=$bucket
db=$db
l="$l"
pid=$pid
sourceBucket=$sourceBucket

#checking params
if [ -z "$pid" ] ; then
    echo "missing PID; exiting"
    exit -1
fi

echo "Get from db=$db bucket=$sourceBucket pid=$pid to $l"
java -jar $orfiles -M Get -l "$l" -h $host -d "$db" -b $sourceBucket -a $pid -m ""

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
fi
