#!/bin/bash

scripts=$scripts
source $scripts/test.unit/stagingfileDerivatives.setup.sh
db=$db
na=$na
fileSet=$fileSet
location=$location
md5=$md5
contentType=$contentType
pid=$pid
folder1=$folder1
folder2=$folder2
custom="$1"
testCounter=0
testTotal=7

# remove the custom derivative material
if [ "$custom" == "true" ]; then
    echo "We are to test custom derivative ingestation. One substitute ( level1 ) and two inserts (level 2 and level 2)"
    testTotal=10
else
    echo "We are to test derivative creation."
    rm $fileSet/.level1/files/*
    rm $fileSet/TIFF/.level2/files/*
    rm $fileSet/TIFF/files/.level3/*
fi

for bucket in "master" "level1" "level2" "level3"
do
	mongo $db --quiet --eval "db.getCollection('$bucket.files').remove()"
	mongo $db --quiet --eval "db.getCollection('$bucket.chunks').remove()"
done

for bucket in "master" "level1" "level2" "level3"
do
    f=${bucket^}
    $scripts/pmq-agents-available/StagingfileIngest$f/startup.sh -na $na -fileSet $fileSet -location $location \
        -md5 $md5 -contentType $contentType -pid $pid  -access "open" -label "Added by unit test"
   
    # We expect to see a file of some substance
    query="db.getCollection('$bucket.files').find({'metadata.pid':'$pid'}).count()"
    count=$(mongo $db --quiet --eval "$query")
    if [ $count == 0 ] ; then
        echo "Query $query should have shown a document in the collection"
        exit -1
    fi
    let testCounter++

done

for bucket in "level1" "level2" "level3"
do
	query="db.master.files.find( {'metadata.cache.metadata.bucket':'$bucket'}).count()"
	count=$(mongo $db --quiet --eval "$query")
	if [ $count == 0 ] ; then
        	echo "Query $query should have shown a document in the cache"
        	exit -1
	fi
    	let testCounter++
done

if [ "$custom" == "true" ] ; then
	query="db.level1.files.find( {'md5':'$md5level1'}).count()"
	count=$(mongo $db --quiet --eval "$query")
	if [ $count == 0 ] ; then
        	echo "Query $query should have shown a document in the cache"
        	exit -1
	fi
	let testCounter++

	query="db.level2.files.find( {'md5':'$md5level2'}).count()"
	count=$(mongo $db --quiet --eval "$query")
	if [ $count == 0 ] ; then
        	echo "Query $query should have shown a document in the cache"
        	exit -1
	fi
	let testCounter++

	query="db.level3.files.find( {'md5':'$md5level3'}).count()"
	count=$(mongo $db --quiet --eval "$query")
	if [ $count == 0 ] ; then
        	echo "Query $query should have shown a document in the cache"
        	exit -1
	fi
	let testCounter++
fi

source $scripts/shared/testreport.sh
