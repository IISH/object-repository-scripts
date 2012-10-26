#!/bin/bash
#
# /StagingfileIngestLevel3Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/primary.sh
source $scripts/shared/parameters.sh

sourceBuckets="level1 master"
targetBucket="level3"

source $scripts/shared/image.derivative.sh
exit $?