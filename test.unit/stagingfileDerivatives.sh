#!/bin/bash

scripts=$scripts
na="12345"
sa_path=$sa_path
cpuser=testuser
folder=unittest
fileName="1_0001.tif"
fileSet=$sa_path/$na/$cpuser/$folder
testfile=$fileSet/$fileName
pid="$na/1"
location="/$cpuser/$fileName"
contentType="image/tiff"
md5=$(md5sum $testfile | cut -d ' ' -f 1)
db=or_$na

testTotal=3
testCounter=0

mkdir -p $fileSet
rm $fileSet/*
cp "$sa_path/$na/.$location" $testfile

mongo $db --quiet --eval "db.getCollection('master.files').remove()"
mongo $db --quiet --eval "db.getCollection('master.chunks').remove()"
mongo $db  --quiet --eval "db.getCollection('files').remove({na:'$na'})"

sh $scripts/pmq-agents-enabled/StagingfileIngestMaster/startup.sh -na $na -fileSet $fileSet -location $location -md5 $md5 -contentType $contentType -pid $pid

for bucket in "level1" "level2" "level3"
do
    startup=$scripts/pmq-agents-enabled/StagingfileIngest$bucket/startup.sh
    sh $startup -na $na -fileSet $fileSet -location $location -md5 $md5 -contentType $contentType -pid $pid

    # We expect to see a derivative
    query="db.getCollection('$bucket.files').find({'metadata.pid':$pid})"
    count=$(mongo $db --quiet --eval "$query")
    if [ $count == 0 ] ; then
        echo "Query $query should have shown a document in the collection"
        exit -1
    fi

    let testCounter++
done

source $scripts/shared/testreport.sh