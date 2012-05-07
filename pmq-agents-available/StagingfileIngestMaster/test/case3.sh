#!/bin/bash
#
# /StagingfileIngestMaster/test/case2.sh
#
# Purpose is to make sure the add and update procedures work well as described
# in /shared/put.js
#
# Case 3
# Here we introduce an existing PID with a file that is bound to a different PID.
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
testTotal=30
testCounter=0


# We will offer pid.0 with file 1
for i in 0 1 2
do
    
    pid0="$na/0.$i"
    filename0="master.0.$i.txt"
    file0="$fileSet/$filename0"
    location0=/$folder/$filename0
    md50=$(md5sum $file0 | cut -d ' ' -f 1)
    length0=$(stat -c%s "$file0")

    pid1="$na/1.$i"
    filename1="master.1.$i.txt"
    file1="$fileSet/$filename1"
    location1=/$folder/$filename1
    md51=$(md5sum $file1 | cut -d ' ' -f 1)
    length1=$(stat -c%s "$file1")

    $scripts/shared/put.sh -na $na -bucket "master" -contentType "image/jpeg" -pid $pid0 \
        -md5 $md51 -location $location1 -access "open" -label "test label" \
        -fileSet $fileSet

    query="{'metadata.pid':'$pid0', md5:'$md51'}"
    count=$(mongo $db --quiet --eval "db.getCollection('master.files').find($query).count()")
    if [ $count == 1 ] ; then
	let testCounter++
    else
    	echo "The query $query ought to have produced a result in the master.files collection."
    	exit -1
    fi
    query="{md5:'$md50'}"
    count=$(mongo $db --quiet --eval "db.getCollection('master.files').find($query).count()")
    if [ $count == 0 ] ; then
        let testCounter++
    else
        echo "The query $query ought not contain a document in the master collection"
        exit -1
    fi

    for bucket in "master" "level1" "level2" "level3"
    do
	    query="{'metadata.pid':'$pid0'}"
	    count=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
	    if [ $count == 1 ] ; then
	        let testCounter++
	    else
	        echo "The query $query ought to find us a document in the collection $bucket"
	        exit -1
	    fi
        query="{'metadata.pid':'$pid1'}"
            count=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
        if [ $count == 0 ] ; then
                let testCounter++
        else
            echo "The query $query ought not contain a document in the collection $bucket"
            exit -1
        fi
    done
done

source $scripts/shared/testreport.sh

