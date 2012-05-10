#!/bin/bash
#
# StagingFileIngestMaster/startup.sh
#
# Insert a Master file into the database

scripts=$scripts
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
if [ -z "$l" ] ; then
    echo "No file found... updating metadata for the $db.$bucket collection"

    e="db.getCollection('$bucket.files').update({'metadata.pid':'$pid'},{\$set:{'metadata.access':'$access', \
    contentType:'$contentType','metadata.label':'$label'}}, false, false); \
    db.getCollection('files').update({'pid':'$pid'}, {\$set:{'access':'$access',label:'$label'}}, false, false);''"
    mongo $db --quiet --eval "$e"
    exit $?
else

    remove=true
    source $scripts/shared/put.sh
    count=$(ls -1 | wc -l)
    if [$count == 0] ; then
	rm -f $fileSet
    fi

fi

exit $?
