#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/parameters.sh

sourceBuckets="master"
targetBucket="level1"

bucket=$targetBucket
source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh

source $scripts/shared/audio.derivative.sh
exit $?