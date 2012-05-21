#!/bin/bash
#
# StagingFileIngestMaster/startup.sh
#
# Insert a Master file into the database

scripts=$scripts
fileSet=$fileSet
bucket="master"
source $scripts/shared/parameters.sh
db=$db
length=$length
md5=$md5
pid=$pid
access=$access
contentType=$contentType
label="$label"
l="$l"

# If we have no file to upload, we basically are talking about an update of metadata
if [ -f "$l" ] ; then

    remove=true
    source $scripts/shared/put.sh
    count=$(ls $fileSet -1 | wc -l)
    if [$count == 0] ; then
        rm -r $fileSet
    fi
else
    echo "No location '$l' found... updating metadata for the $db.$bucket collection"

    e="db.getCollection('$bucket.files').update({'metadata.pid':'$pid'},{\$set:{'metadata.access':'$access', \
    contentType:'$contentType','metadata.label':'$label'}}, false, false); \
    db.getCollection('files').update({'pid':'$pid'}, {\$set:{'access':'$access',label:'$label'}}, false, false);''"
    mongo $db --quiet --eval "$e"
    exit $?
fi

exit $?

