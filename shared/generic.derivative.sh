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

sourceFile=$(php $scripts/shared/generic.derivative.php -l $location -b $targetBucket)
if [ -f $sourceFile ]; then
    useCustom=true
    contentType=(php $scripts/shared/contenttype.php -l $sourceFile)
    content=$(identify -format "{height:'%h',width:'%w',x-resolution:'%x',y-resolution:'%y'}" $sourceFile)
    remove=true
    $scripts/shared/put.sh
fi