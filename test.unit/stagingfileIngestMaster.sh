#!/bin/bash
#
# StagingfileBindPIDs/test/stagingfilePut.instructionSetup.sh
#
# Unit test using startup.sh
#

scripts=$scripts
na="12345"
sa_path=$sa_path
testuser="testuser"
folder="unittest"
fileSet=$sa_path/$na/$testuser/$folder
cpkey=$cpkey
cpendpoint=$cpendpoint
testTotal=75
testCounter=0


mongo or_$na --quiet --eval "db.getCollection('master.files').remove()"
mongo or_$na --quiet --eval "db.getCollection('master.chunks').remove()"
mongo or_$na --quiet --eval "db.getCollection('files').remove({na:'$na'})"


# What we expect is to find our files in teh database
# And each PID we expect to see in the PID webservice with the resolve URLs.
rm $fileSet/*
for i in 1 2 3 4 5
do
    for j in 1 2 3 4 5
    do
        bucket="master"
        filename="$bucket.$i.$j.txt"
        file="$fileSet/$filename"
        echo $file > $file
        md5=$(md5sum $file | cut -d ' ' -f 1)
        pid=$na/$i.$j
        loc="/$folder/$filename"
        id="4fa423600cf2ff68e47d9c$i$j"
        name="Test"
        $scripts/pmq-agents-available/StagingfileIngestMaster/startup.sh -pid "$pid" -na $na -fileSet $fileSet -id $id \
            -name $name -bucket $bucket -contentType "text/plain" -md5 $md5 -access "open" -location $loc \
            -label "hello $pid"
        db=or_$na
        count=$(mongo $db --quiet --eval "db.getCollection('master.files').find({'pid.metadata':$pid}).count()")
        if [ $count != 0 ] ; then
            echo "Did not find a master with pid $pid"
            exit -1
        fi
        let testCounter++

	count=$(mongo $db --quiet --eval "db.getCollection('files').find({'pid':$pid}).count()")
        if [ $count != 0 ] ; then
            echo "Did not find a metadata file with pid $pid"
            exit -1
        fi
        let testCounter++
    done
done

# Now test metadata updates
bucket="master"
for i in 1 2 3 4 5
do
    for j in 1 2 3 4 5
    do
        filename="$bucket.$i.$j.txt"
        file="$fileSet/$filename"
        rm $file
        pid=$na/$i.$j
        id="4fa423600cf2ff68e47d9c$i$j"
        name="Test"
        access="liberal"
        label="hello Galifrey $pid"
        contentType="text/realySimple"
        $scripts/pmq-agents-available/StagingfileIngestMaster/startup.sh -pid "$pid" -na $na -fileSet $fileSet -id $id \
         -name $name -bucket $bucket -contentType $contentType -md5 $md5 -access $access -label "$label"

        query="{'metadata.pid':'$pid'}"
        e="db.getCollection('$bucket.files').findOne($query).contentType"
        checkContentType=$(mongo $db --quiet --eval "$e")
        if [ "$checkContentType" != "$contentType" ] ; then
            echo "ContentType did not alter. Expect $contentType but actual $checkContentType"
            exit -1
        fi
        checkLabel=$(mongo $db --quiet --eval "db.getCollection('master.files').findOne($query).metadata.label")
        if [ "$checkLabel" != "$label" ] ; then
            echo "Label did not alter. Expect $label but actual $checkLabel"
            exit -1
        fi
        checkAccess=$(mongo $db --quiet --eval "db.getCollection('master.files').findOne($query).metadata.access")
        if [ "$checkAccess" != "$access" ] ; then
            echo "Access did not alter. Expect $checkAccess but actual $access"
            exit -1
        fi

        let testCounter++

    done
done

source $scripts/shared/testreport.sh
