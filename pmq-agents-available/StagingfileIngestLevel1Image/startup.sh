#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

scripts=$scripts
source $scripts/shared/parameters.sh

sourceBuckets="master"
bucket="level1"

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh
source $scripts/shared/image.derivative.sh
exit $?