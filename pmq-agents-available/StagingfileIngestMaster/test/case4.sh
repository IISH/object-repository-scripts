#!/bin/bash
#
# /StagingfileIngestMaster/test/case4.sh
#
# Purpose is to make sure the add and update procedures work well as described
# in /shared/put.js
#
#
# put Case 4
# Adding new file, yet with a previously used pid.
# THe new file is added with the existing pid and the old files need to be removed.
#



scripts=$scripts
source $scripts/pmq-agents-available/StagingfileIngestMaster/test/setup.sh
na=$na
sa_path=$sa_path
fileSet=$fileSet
folder=$folder
db=$db
manual=$manual
orfiles=$orfiles
make=$make
manual=$manual
testTotal=15
testCounter=0


# We fill replace the master.2 files with master.3
for i in 0 1 2
do
    pid="$na/2.$i"
    query="{'metadata.pid':'$pid'}"
    oldMD5=$(mongo $db --quiet --eval "db.getCollection('master.files').findOne($query).md5")
    filename="master.3.$i.txt"
    location="/$folder/$filename"
    file="$fileSet/$filename"

    md5=$(md5sum $file | cut -d ' ' -f 1)
    $scripts/shared/put.sh -na $na -bucket "master" -contentType "image/tif" -pid $pid -md5 $md5 \
        -location $location -access "open" -label "test label master" \
        -resolverBaseUrl "a resolverBaseUrl" -fileSet $fileSet

    query="{md5:'$oldMD5'}"
    count=$(mongo $db --quiet --eval "db.getCollection('master.files').find($query).count()")
    if [ $count == 0 ] ; then
	    let testCounter++
    else
        echo "Should not see a document with query $query but still it is there in the master bucket"
        exit -1
    fi
    query="{md5:'$md5','metadata.pid':'$pid'}"
    count=$(mongo $db --quiet --eval "db.getCollection('master.files').find($query).count()")
    if [ $count == 1 ] ; then
	    let testCounter++
    else
        echo "Could not find a new document with query $query in the master bucket"
        exit -1
    fi

    for bucket in "level1" "level2" "level3"
    do
	    query="{'metadata.pid':'$pid'}"
        count=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
	    if [ $count == 0 ] ; then
            let testCounter++
    	else
            echo "Should not see a document with query $query in $bucket because the master has been given a new file."
            exit -1
        fi
    done
	
done

source $scripts/shared/testreport.sh
