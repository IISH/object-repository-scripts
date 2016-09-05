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
# Preset 120 = Audio Only: MP3 High Quality
preset="120"
targetContentType="audio/mpeg"
derivative="audio"
format="mp3"
mvccl_opts="/cuda"

source $scripts/shared/delete.sh
source $scripts/shared/hasdocument.sh

source $scripts/shared/video.windows.derivative.sh
exit $?