#!/bin/bash

db=$db
targetBucket=$targetBucket
pid=$pid
scripts=$scripts
hasdocument=$(mongo $db --quiet --eval "var bucket='$targetBucket';var pid='$pid'" $scripts/shared/hasdocument.js)
if [ "$hasdocument" == "true" ] ; then
    echo "The file in $targetBucket with $pid exists. Hence we stop processing here."
    exit 245
fi