#!/bin/bash
#
# /StagingfileIngestLevel2Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh
source $scripts/shared/parameters.sh

sourceBuckets="level1 master"
targetBucket="level2"

source $scripts/shared/image.derivative.sh
exit $?