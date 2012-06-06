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

# If we find a file we upload it
if [ -f "$l" ] ; then

    remove=true
    source $scripts/shared/put.sh
    #count=$(ls $fileSet -1 | wc -l)
    #if [$count == 0] ; then
    #    echo "The folder $fileSet can be deleted. We leave this up to the end user."
    #fi
else
    echo "No location '$l' found... updating metadata for the $db.$bucket collection"
    mongo $db --quiet --eval "db.getCollection('$bucket.files').update({'metadata.pid':'$pid'}, \
        {\$set:{'metadata.access':'$access',contentType:'$contentType','metadata.label':'$label'}}, false, false);''"
    exit $?
fi

exit $?

