#!/bin/bash
#
# /shared/derivative.sh
#
# See if custom and ready made derivatives already are in the expected place.
# If not, choose the appropriate conversion script to generate a derivative.

scripts=$scripts
source $scripts/shared/parameters.sh
sourceBuckets=$sourceBuckets
targetBucket=$targetBucket
useCustom=$useCustom
derivative=$derivative
md5=$md5

$scripts/shared/generic.derivative.sh

if [ "$useCustom" == "false" ] ; then
    file="$scripts/shared/$derivative".derivative.sh
    if [ -f $file ] ; then
        source $scripts/shared/image.derivative.sh $@ -sourceBuckets $sourceBuckets -targetBucket $targetBucket
    fi
fi

rc=$?
if [[ $rc != 0 ]] ; then
    exit $rc
else
    $scripts/shared/success.sh "$@"
    targetFile=/tmp/$md5.$targetBucket.jpg
    rm -f $targetFile
fi

exit 0
