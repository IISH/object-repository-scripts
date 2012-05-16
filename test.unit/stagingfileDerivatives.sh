#!/bin/bash

source $scripts/test.unit/stagingfileDerivatives.setup.sh

for bucket in "master" "level1" "level2" "level3"
do
	mongo $db --quiet --eval "db.getCollection('$bucket.files').remove()"
	mongo $db --quiet --eval "db.getCollection('$bucket.chunks').remove()"
done
mongo $db --quiet --eval "db.getCollection('files').remove({na:'$na'})"

for bucket in "master" "level1" "level2" "level3"
do
    f=${bucket^}
    $scripts/pmq-agents-available/StagingfileIngest$f/startup.sh -na $na -fileSet $fileSet -location $location \
        -md5 $md5 -contentType $contentType -pid $pid  -access "open" -label "Added by uittest"
   
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
