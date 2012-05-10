#!/bin/bash
#
# integrationtest/lid.sh
#
# Integration test
#
# Verify if we can bind PIDs using the workflow service and message queue.
# Here we test the autoGeneratePIDs==none option where we supply our own custom pids.
#
# We set a profile in the staging area with the given na 12345
# A pmq-agent must be enabled and listening to the queue 'StagingfileBindPIDs' and 'StagingfileInsertMaster'
#

scripts=$scripts
na="12345"
sa_path=$sa_path
folder="unittest"
fileSet=$sa_path/$na/$folder
cpkey=$cpkey
cpendpoint=$cpendpoint
testTotal=101
testCounter=0
action="upsert"
autoGeneratePIDs="lid"
source $scripts/pmq-agents-available/integrationtest/setup.sh
db=$db
key=$key
endpoint=$endpoint

echo "====================================================================="

# as the files are being processed, we just have to wait a bit and see...
failSafe=0
remember=0

while [ $failSafe -lt 100 ]
do
    sleep 5
    let failSafe++
    f=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find( {failure:{\$size:0}} ).count()")
    if [ $f != 0 ] ; then
        echo "There are $f failures..."
        exit -1
    fi
    count=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find({fileSet:'$fileSet'}).count()")
    if [ $count == 0 ] ; then
	    echo "Instruction completed."
        let testCounter++
	    break
    fi

	echo "Files in stagingfile collection: $count"

    if [ $remember != $count ] ; then
        failSafe=0
        remember=$count
    fi
done

# What we expect is to find our files in the database
# And each PID we expect to see in the PID webservice with the resolve URLs.i
# However, now we do not know what that pid is.
for i in 1 2 3 4 5
do
    for j in 1 2 3 4 5
    do
        filename="master.$i.$j.txt"
        file=$fileSet/$filename
        if [ -f $file ] ; then
            echo "The file $file ought to have been removed."
            exit -1
        fi
        let testCounter++

	pid=$na/$i.$j
        lid="lid.$pid"
	query="{'metadata.lid':'$lid'}"
        count=$(mongo $db --quiet --eval "db.getCollection('files').find($query).count()")
        if [ $count != 1 ] ; then
            echo "The expected lid $lid; but it is not in the database"
            exit -1
        fi
	let testCounter++

	pid=$(mongo $db --quiet --eval "db.getCollection('files').findOne($query).metadata.pid")
	if [ ${#pid} != 42 ] ; then
	    echo "We ought to get an UUID shaped PID value."
	    exit -1
	fi
    done
done

source $scripts/shared/testreport.sh

echo $testCounter
