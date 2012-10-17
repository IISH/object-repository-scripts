#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh

sourceBuckets="level1 master"
targetBucket="level2"

source $scripts/shared/audio.derivative.sh
exit $?