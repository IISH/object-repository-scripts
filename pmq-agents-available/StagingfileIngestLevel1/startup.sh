#!/bin/bash
#
# /StagingfileIngestLevel1/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
sourceBuckets="master"
targetBucket="level1"
source $scripts/shared/derivative.sh
derivative=$derivative

source $scripts/shared/limit_connections.sh

file="$scripts/shared/$derivative".derivative.sh
if [ -f "$file" ] ; then
    source $file
fi

exit $?