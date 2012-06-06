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
custom=$custom
testCounter=0
testTotal=4

# remove the custom derivative material
if [ ! -z "$custom" ]; then
    echo "We are to test derivative creation"
    rm $fileSet/.level1/*
    rm $fileSet/TIFF/.level2/*
else
    echo "We are to test custom derivative ingestation"
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

source $scripts/shared/testreport.sh
