#!/bin/bash
#
# StagingfileBindPIDs/test/lid.sh
#
# Integration test
#
# Verify if we can bind PIDs using the workflow service and message queue.
# Here we test the autoGeneratePIDs=lid option.
#
# The profile must already have been set for the staging area with the given $test_na. (12345)
# An instruction must be in the fileSet that triggers a process.
# A pmq-agent must be enabled and listening to the queue 'StagingfileBindPIDs'
#

scripts=$scripts
na="12345"
sa_path=$sa_path
folder="unittest"
fileSet=$sa_path/$na/$folder
cpkey=$cpkey
cpendpoint=$cpendpoint
testTotal=15
testCounter=0
action="upsert"
autoGeneratePIDs="lid"
source $scripts/pmq-agents-available/StagingfileBindPIDs/test/setup.sh
db=$db
key=$key
endpoint=$endpoint

echo "====================================================================="

# as the instruction is created, we have to wait for the result.
for i in {0..100}
do
    sleep 1
    name=$(mongo sa --quiet --eval "db.getCollection('instruction').findOne({fileSet:'$fileSet'}).task.name")
    if [ "$name" == "InstructionDone" ] ; then
	echo "Instruction completed."
        let testCounter++
	break
    fi
    echo "Status: $name"
    if [ $i -gt 80 ]; then
	echo "The instruction is not completed in the expected time."
	exit -1
    fi
done

# What we expect is to find our files in teh database
# And each PID we expect to see in the PID webservice with the resolve URLs.
for i in 1 2 3 4 5
do
    for j in 1 2 3 4 5
    do
        filename="master.$i.$j.txt"
        location=$fileSet/$filename
        if [ -f $location ] ; then
            echo "The file $location ought to have been removed."
            exit -1
        fi
        let testCounter++

        pid=$na/$i.$j
	count=$(mongo $db --quiet --eval "db.getCollection('files').find({pid:'$pid'}).count()")
	if [ $count == 0 ] ; then
	    echo "The expected pid $pid is not in the database"
	    exit -1
	fi
	let testCounter++

	soapenv="<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' \
                              xmlns:pid='http://pid.socialhistoryservices.org/'> \
                <soapenv:Body> \
                    <pid:GetPidRequest> \
                        <pid:pid>$pid</pid:pid> \
                    </pid:GetPidRequest> \
                </soapenv:Body> \
            </soapenv:Envelope>"

	log=/tmp/$filename
	rm $log
    wget -O $log --header="Content-Type: text/xml" --header="Authorization: oauth $key" --post-data "$soapenv" --no-check-certificate $endpoint
	if [ ! -f $log ] ; then
	    echo "The PID webservice did not gave a valid response."
	    exit -1
	fi

	l=$fileSet/$filename
	pidCheck=$(php $scripts/pmg-agents-available/StagingfileBindPIDs/test/pid.php -l $l)
	if [ "$pidCheck" != "$pid" ] ; then
	    echo "Pid not returned by webservice"
	    exit -1
	fi

    done
done	
