#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh

sourceBuckets="master"
targetBucket="level1"
derivative=$derivative

file="$scripts/shared/$derivative".derivative.sh
if [ -f "$file" ] ; then
    source $file
fi

echo "We cannot make a derivative of type $derivative"
echo "This is not an error. Just there is no such service."
exit 250