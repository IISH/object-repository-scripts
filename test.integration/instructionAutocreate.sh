#!/bin/bash
#
# integrationtest/instructionFilename2lid.sh
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
testTotal=26
testCounter=0
action="upsert"
autoGeneratePIDs="filename2pid"
autocreateInstruction=true
source $scripts/test.integration/instructionSetup.sh
db=$db
key=$key
endpoint=$endpoint

echo "====================================================================="

ls $fileSet -al

failSafe=0
remember=0

sleep 30
count=$(ls $fileSet -1 | wc -l)
if [ $count != 25 ] ; then
	echo "No files ought ot have been processed."
	exit -1
fi
let failSafe++

# Now run the workflow: autoIngestValidInstruction:false
mongo sa --quiet --eval "db.getCollection('instruction').update({fileSet:'$fileSet','workflow.n':0}, \
	{\$set:{autoGeneratePIDs:'filename2pid',autoIngestValidInstruction:false,'workflow.$.name':'InstructionAutocreate', \
	'workflow.$.statusCode':100, plan:['StagingfileIngestMaster,StagingfileBindPIDs']}}, false, false)"

while [ $failSafe -lt 100 ]
do
    sleep 5
    let failSafe++
    count=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find({fileSet:'$fileSet'}).count()")
    if [ $count == 25 ] ; then
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

# Nothing will happen now... pids are there, but no automatic ingest: autoIngestValidInstruction:'false'
# What we expect is to find our files in the database
echo "Wait for some time... ingest ought not to happen."
sleep 60

for i in 1 2 3 4 5
do
    for j in 1 2 3 4 5
    do
	pid=$na/$i.$j
	 filename="$i.$j.txt"
        file=$fileSet/$filename
        if [ ! -f "$file" ] ; then
            echo "The file $file ought not to have been removed."
            exit -1
        fi
        let testCounter++
    done
done

source $scripts/shared/testreport.sh

echo $testCounter
