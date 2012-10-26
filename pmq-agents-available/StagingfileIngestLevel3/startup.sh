#!/bin/bash
#
# /StagingfileIngestLevel3Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh
source $scripts/shared/parameters.sh

sourceBuckets="level1 master"
targetBucket="level3"
derivative=$derivative

file="$scripts/shared/$derivative".derivative.sh
if [ -f "$file" ] ; then
    source $file
fi

echo "We cannot make a derivative of type $derivative"
echo "This is not an error. Just there is no such service."
exit 250