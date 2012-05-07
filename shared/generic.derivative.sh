#!/bin/bash
#
# Create or fetch a derivative
# If we can find it, then ingest the derivative into the correct bucket.
#

scripts=$scripts
bucket=$bucket
location=$location
targetBucket=$targetBucket
shouldHave=$shouldHave
db=$db
pid=$pid

useCustom=false
sourceFile=$(php $scripts/shared/generic.derivative.php -l $location -b $targetBucket)
if [ -f $sourceFile ]; then
    useCustom=true
    contentType=(php $scripts/shared/contenttype.php -l $sourceFile)
    content=$(identify -format "{height:'%h',width:'%w',x-resolution:'%x',y-resolution:'%y'}" $sourceFile)
    $scripts/shared/put.sh
    length=$(stat -c%s "$sourceFile")
    shouldHave=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne({pid:'$pid',length:$length}).metadata.pid")
    if [ "$shouldHave" == "$pid" ] ; then
        rm -f $sourceFile
        exit 0
    else
        echo "Error. No file found with the expected pid and length."
        exit 1
    fi
fi