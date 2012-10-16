#!/bin/bash
#
# /StagingfileIngestLevel3/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh

sourceBuckets="level1 master"
targetBucket="level3"
derivative=$derivative

file="$scripts/shared/$derivative".derivative.sh
if [ -f "$file" ] ; then
    source $file
fi

exit $?
