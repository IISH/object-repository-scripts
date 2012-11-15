#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh

sourceBuckets="level1 master"
targetBucket="level3"

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh
source $scripts/shared/audio.derivative.sh
exit $?