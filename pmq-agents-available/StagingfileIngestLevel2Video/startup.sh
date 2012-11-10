#!/bin/bash
#
# /StagingfileIngestLevel1Image/startup.sh
#
# The convert script to create the level 2 derivative
# Here we create 4 x 4 stilled images

scripts=$scripts
source $scripts/shared/secondaries.sh
source $scripts/shared/parameters.sh
bucket=level1

action=$action
if [ "$action" == "delete" ] ; then
    source $scripts/shared/delete.sh
    exit $?
fi

db=$db
nb_frames=$(mongo $db --quiet --eval "var doc=db.master.files.findOne('metadata.pid':'\$pid',{'metadata.content':1}); \
    if (doc) {\
        doc.metadata.content.streams.forEach(function(d){if (d.codec_type=='video ') print(d.nb_frames)})
    }")