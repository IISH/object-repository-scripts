#!/bin/bash
#
# /StagingfileIngestMaster/test/case1.sh
#
# Purpose is to make sure the add and update procedures work well as described
# in /shared/put.js
#
# put Case 1
# Here we introduce a new PID for the same file... the new PID should me bound to that existing file.
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
testTotal=72
testCounter=0


for i  in 0 1 2
do
    for j in 0 1 2
    do
	oldPid="$na/$i.$j"
	newPid="$oldPid.newPid"
	filename="master.$i.$j.txt"
	file=$fileSet/$filename
	echo "file=$file"
	location="/$folder/$filename"
	md5=$(md5sum $file | cut -d ' ' -f 1)
	$scripts/shared/put.sh -na $na -bucket "master" -contentType "image/jpeg" -pid $newPid -md5 $md5 \
            -location $location -access "open" -label "test label" -fileSet $fileSet
	
	for bucket in "master" "level1" "level2" "level3"
	do
	    query="{'metadata.pid':'$newPid'}"
	    count=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
	    if [ $count == 1 ] ; then
	        let testCounter++
	    else
    	        echo "There ought to new a file with the new PID $newPid, but there are $count"
    	        exit -1
	    fi
	    query="{'metadata.pid':'$oldPid'}"
	    count=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
	    if [ $count == 0 ] ; then
		let testCounter++
	    else
  	        echo "This PID $oldPid ought to have been replaced by $newPid"
	        exit -1
	    fi
	done
    done
done

source $scripts/shared/testreport.sh

