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

source $scripts/shared/generic.derivative.sh

# If we are here in this script, it is because there was no custom derivative provided.
file="$scripts/shared/$derivative.derivative.sh"
if [ -f "$file" ] ; then
    echo "Loading $file"
    source $file
else
    echo "We cannot make a derivative of type $derivative"
    echo "This is not an error. Just there is no such service."
    exit 0
fi
