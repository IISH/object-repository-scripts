#!/bin/bash
#
# integrationtest/instructionFilename2lid.sh
#
# Integration test
#
# Test to see if we can ingest 10 master images
# 1.1.tiff has three custom level derivatives
# The others not thus we expect the image magick service
#
# We make the filename the PID value

scripts=$scripts
na="12345"
sa_path=$sa_path
folder="unittest"
cpkey=$cpkey
cpendpoint=$cpendpoint
testTotal=10
testCounter=0
action="upsert"
autoGeneratePIDs="filename2pid"
autocreateInstruction=false
fileSet="/tmp"
source $scripts/test.integration/instructionSetup.sh
db=$db
key=$key
endpoint=$endpoint

echo "====================================================================="

rm -r /mnt/sa/12345/testuser/unittest
mkdir -p /mnt/sa/12345/testuser/unittest
cp -r /mnt/sa/12345/.testuser/unittest/TIFF $fileSet
chown -R $na:$na /mnt/sa/12345/testuser/unittest

ls $fileSet/TIFF/files  -al

failSafe=0
remember=0

echo "Give the workflow controller some timem to detect the fileSet."
sleep 10

# Now run the workflow: autoIngestValidInstruction:false
echo "fileSet=$fileSet"
query="{fileSet:'$fileSet','workflow.n':0}"
update="{\$set:{autoGeneratePIDs:'filename2pid',autoIngestValidInstruction:true,contentType:'image/tiff','workflow.$.name':'InstructionAutocreate', \
        'workflow.$.statusCode':100, plan:null}}"
echo "query=$query"
echo "update=$update"
mongo sa --quiet --eval "db.getCollection('instruction').update($query, $update, false, false)"

while [ $failSafe -lt 100 ]
do
    sleep 5
    let failSafe++
    count=$(mongo sa --quiet --eval "db.getCollection('stagingfile').find({fileSet:'$fileSet'}).count()")
    echo "Stagingfiles $count/9"
    if [ $count == 9 ] ; then
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

# As the autoIngest procedure is running... ingest will commence
echo "Wait for some time... ingest ought not to happen."
sleep 60

source $scripts/shared/testreport.sh

