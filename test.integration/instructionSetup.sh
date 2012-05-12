#!/bin/bash
#
# StagingfileBindPIDs/test/stagingfilePut.instructionSetup.sh
#
# Integration test
#

scripts=$scripts
na="12345"
sa_path=$sa_path
cpuser=testuser
folder=unittest
fileSet=$sa_path/$na/$cpuser/$folder
source $scripts/shared/parameters.sh -na $na -fileSet $fileSet -folder $folder
key=$key
endpoint=$endpoint
autoGeneratePIDs=$autoGeneratePIDs
autocreateInstruction=$autocreateInstruction
action="upsert"

mkdir -p $fileSet
rm $fileSet/*

# empty our profile, instruction and stagingfile collections
query="{na:'$na'}"
mongo sa --quiet --eval "db.getCollection('profile').remove($query)"
mongo sa --quiet --eval "db.getCollection('instruction').remove($query)"
mongo or_$na --quiet --eval "db.getCollection('master.files').remove()"
mongo or_$na --quiet --eval "db.getCollection('master.chunks').remove()"
mongo or_$na  --quiet --eval "db.getCollection('files').remove({na:'$na'})"
query="{fileSet:'$fileSet'}"
mongo sa --quiet --eval "db.getCollection('stagingfile').remove($query)"
# Add a profile with a default workflow that only processes the StagingfileBindPIDs
profile="{na:'$na', action:'upsert',access:'open',contentType:'text/plain',resolverBaseUrl:'http://hdl.handle.net/', 
    autoGeneratePIDs:'none',autoIngestValidInstruction:true,pidwebserviceEndpoint:null,pidwebserviceKey:null, \
    workflow:[ \
	{ \
                  'attempts' : 1, \
                  'end' : ISODate('2012-01-01T00:00:00.000Z'), \
                  'failure' : false, \
                  'info' : 'Default workflow unittest', \
                  'limit' : 3, \
                  'name' : 'StagingfileIngestMaster', \
                  'processed' : 0, \
                  'start' : ISODate('2012-01-01T00:00:00.000Z'), \
                  'statusCode' : 0, \
                  'total' : 0, \
		  'exitValue' : 123, \
                  'version' : 0 } \
                  , \
          	  { \
                  'attempts' : 1, \
                  'end' : ISODate('2012-01-01T00:00:00.000Z'), \
                  'failure' : false, \
                  'info' : 'Default workflow unittest', \
                  'limit' : 3, \
                  'name' : 'StagingfileBindPIDs', \
                  'processed' : 0, \
                  'start' : ISODate('2012-01-01T00:00:00.000Z'), \
                  'statusCode' : 0, \
                  'exitValue' : 123, \
                  'total' : 0, \
                  'version' : 0 } \
                  ] }"
echo "profile=$profile"
mongo sa --eval "db.getCollection('profile').save($profile)"

#  Get some 25 test files with the instruction. Remove any PIDs in the pid webservice.
# We alway use a custom pid that we know.
instruction="$fileSet/instruction.xml"
echo "<instruction xmlns='http://objectrepository.org/instruction/1.0/' autoIngestValidInstruction='true' autoGeneratePIDs='$autoGeneratePIDs' action='$action'>" > $instruction
for i in 1 2 3 4 5
do
    for j in 1 2 3 4 5
    do
        filename="$i.$j.txt"
        pid=$na/$filename
        file="$fileSet/$filename"
        echo $file > $file
        location=/$folder/$filename
        md5=$(md5sum $file | cut -d ' ' -f 1)
	    lid="lid.$pid"
            echo "<stagingfile>" >> $instruction
            echo "<location>$location</location>" >> $instruction
            if [ "$autoGeneratePIDs" == "none" ]; then
                echo "<pid>$pid</pid>" >> $instruction
            fi
		
            if [ "$autoGeneratePIDs" == "lid" ]; then
                echo "<lid>$lid</lid>" >> $instruction
            fi
            echo "<md5>$md5</md5>" >> $instruction
            echo "</stagingfile>" >> $instruction

        # Remove the pid
        soapenv="<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' \
                              xmlns:pid='http://pid.socialhistoryservices.org/'> \
                <soapenv:Body> \
                    <pid:DeletePidRequest> \
                        <pid:pid>$pid</pid:pid> \
                    </pid:DeletePidRequest> \
                </soapenv:Body> \
            </soapenv:Envelope>"

        log=/tmp/$pid
        wget -O $log --header="Content-Type: text/xml" --header="Authorization: oauth $key" --post-data "$soapenv" --no-check-certificate $endpoint

	if [ -f $log ] ; then
            echo "DeletePidRequest(pid:'$pid')"
        else
            echo "Error: could not call webservice."
            echo $soapenv
	    echo "with key $key and endpoint $endpoint"
	    exit -1
        fi
    done
done

if [ -z "$autocreateInstruction" ] ; then
    echo "</instruction>" >> $instruction
    # That ought to do it. We now need to wait for the system to ingest the instruction.
for i in {1..60}
do
	sleep 1
	echo "$i. Check for removal of $instruction"
	if [ ! -f $instruction ] ; then
	    break
	fi
done
	if [ -f $instruction ] ; then
		echo "The instruction was not removed within in the expected time."
		exit -1
	fi
else
    rm $instruction
fi
