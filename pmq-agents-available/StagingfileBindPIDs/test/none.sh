#!/bin/bash
#
# StagingfileBindPIDs/test/test.sh
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
testTotal=15
testCounter=0
action="upsert"
autoGeneratePIDs="none"
source $scripts/pmq-agents-available/StagingfileBindPIDs/test/setup.sh
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

    if [ $remember != $count ] ; then
        failSafe = 0
        remember=$count
    fi
done

# What we expect is to find our files in the database
# And each PID we expect to see in the PID webservice with the resolve URLs.
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
	    rm -f $log
        wget -O $log --header="Content-Type: text/xml" --header="Authorization: oauth $key" --post-data "$soapenv" \
            --no-check-certificate $endpoint
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
