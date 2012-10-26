#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh
source $scripts/shared/parameters.sh

sourceBuckets="master"
targetBucket="level1"
derivative=$derivative

source $scripts/shared/video.derivative.sh
exit $?