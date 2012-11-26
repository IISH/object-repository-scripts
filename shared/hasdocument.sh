#!/bin/bash

db=$db
bucket=$bucket
pid=$pid
scripts=$scripts
hasdocument=$(mongo $db --quiet --eval "var bucket='$bucket';var pid='$pid'" $scripts/shared/hasdocument.js)
if [ "$hasdocument" == "true" ] ; then
    echo "The file in $bucket with $pid exists. Hence we stop processing here."
    exit 245
fi