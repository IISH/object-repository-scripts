#!/bin/bash
#
# /StagingfileIngestLevel3Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh

sourceBuckets="level1 master"
targetBucket="level3"

action=$action
if [ "$action" == "delete" ] ; then
    bucket=$targetBucket
    source $scripts/shared/delete.sh
    exit $?
fi

source $scripts/shared/image.derivative.sh
exit $?