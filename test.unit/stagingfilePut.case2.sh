#!/bin/bash
#
# /StagingfileIngestMaster/test/stagingfilePut.case2.sh
#
# Purpose is to make sure the add and update procedures work well as described
# in /shared/put.js
#
# Use stagingfilePut.case2.sh make to reconstruct the database and testfiles

scripts=$scripts
source $scripts/pmq-agents-available/test.unit/setup.sh
na=$na
sa_path=$sa_path
fileSet=$fileSet
folder=$folder
db=$db
manual=$manual
orfiles=$orfiles
make=$make
manual=$manual
testTotal=360
testCounter=0


#-------------------------------------------------------------------------------
#
# put Case 2
# Repetitive addition for the same files with the same PID
#
#
#
for bucket in "master" "level1" "level2" "level3"
do
    for i in 0 1 2
    do
        for j in 0 1 2
        do
	    pid=$na/$i.$j
	    filename=$bucket.$i.$j.txt
            file="$fileSet/$filename"
            location="/$folder/$filename"
            md5=$(md5sum $file | cut -d ' ' -f 1)

            for puts in 1 2
            do
                $scripts/shared/put.sh -na $na -bucket $bucket -contentType "image/jpeg" -pid $pid -md5 $md5 -location $location \
                    -action "open" -label "$pid" -fileSet $fileSet
		count=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find({'metadata.label':'$pid'}).count()")
		if [ $count == 1 ]; then
		    let testCounter++
		else
                    echo "Expected 1 document in $bucket, not actual $count"
                    exit -1
            	fi
	    done
        done
    done
done
source $scripts/shared/manual.sh $manual "Case 2: metadata update did not lead to change in file count. Good."


#-------------------------------------------------------------------------------
#
# put Case 2
# Metadata changes where file and PID remain the same.
#
#
#
for bucket in "master" "level1" "level2" "level3"
do
    for i in 1 2
    do
        for j in 1 2
        do
            pid=$na/$i.$j
	    filename=$bucket.$i.$j.txt
            file="$fileSet/$filename"
            location="/$folder/$bucket.$i.$j.txt"
            md5=$(md5sum $file | cut -d ' ' -f 1)
            query="{'metadata.pid':'$pid'}"
            firstUploadDate=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.firstUploadDate")
            lastUploadDate=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.lastUploadDate")
            timesUpdated=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.timesUpdated")
            for access in "restricted" "closed" "open"
            do
                label="$access label"
                $scripts/shared/put.sh -na $na -bucket $bucket -contentType "image/jpeg" -access $access -pid $pid -md5 $md5 -location $location -label "$label" -fileSet $fileSet
                accessCheck=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.access")
                labelCheck=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.label")
                firstUploadDateCheck=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.firstUploadDate")
                lastUploadDateCheck=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.lastUploadDate")
                timesUpdatedCheck=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.timesUpdated")

                if [ "$accessCheck" == "$access" ]; then
		    let testCounter++
		else
                    echo "Access metadata element ought to have changed from $accessCheck into $access"
                    exit -1
                fi
                if [ "$labelCheck" == "$label" ]; then
		    let testCounter++
		else
                    echo "Label metadata element ought to have changed from $labelCheck into $label"
                    exit -1
                fi
                if [ "$firstUploadDateCheck" == "$firstUploadDate" ]; then
		    let testCounter++
		else
                    echo "Uploaddate ought to remain the same."
                    exit -1
                fi
                if [ "$lastUploadDateCheck" == "$lastUploadDate" ]; then
                    echo "Last upload date $lastUploadDateCheck ought to differ from $lastUploadDate."
                    exit -1
		else
		    let testCounter++
                fi
                if [ "$lastUploadDateCheck" == "$lastUploadDate" ]; then
                    echo "Last upload date $lastUploadDateCheck ought to differ from $lastUploadDate."
                    exit -1
		else
		    let testCounter++
                fi
                let "timesUpdated++";
                if [ $timesUpdatedCheck == $timesUpdated ]; then
		    let testCounter++
		else
                    echo "Expected timesUpdated is $timesUpdated but found $timesUpdatedCheck"
                    exit -1
                fi
            done
        done
    done
done
source $scripts/shared/manual.sh $manual "Metadata access, label, lastUpload all updated"

source $scripts/shared/testreport.sh
