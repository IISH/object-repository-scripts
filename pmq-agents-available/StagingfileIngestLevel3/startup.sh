#!/bin/bash
#
# /StagingfileIngestLevel3/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
sourceBuckets=("level1" "master")
targetBucket="level3"
source $scripts/shared/derivative.sh
derivative=$derivative

source $scripts/shared/limit_connections.sh

file="$scripts/shared/$derivative".derivative.sh
if [ -f "$file" ] ; then
    source $file
fi

exit $?
