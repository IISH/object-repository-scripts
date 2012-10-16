#!/bin/bash
#
# /StagingfileIngestLevel1/startup.sh
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

exit $?