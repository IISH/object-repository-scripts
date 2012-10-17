#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh

sourceBuckets="master"
targetBucket="level1"

source $scripts/shared/image.derivative.sh
exit $?