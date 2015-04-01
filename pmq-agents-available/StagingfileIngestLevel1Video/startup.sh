#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 1 derivative

source /etc/environment
scripts=$scripts
source $scripts/shared/parameters.sh

sourceBuckets="master"
bucket="level1"
# Preset 4169 = H.264 AAC ; same framerate as input
preset="4169"
targetContentType="video/mp4"
derivative="video"
format="mp4"
mvccl_opts="/cuda"

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh

source $scripts/shared/video.windows.derivative.sh
exit $?