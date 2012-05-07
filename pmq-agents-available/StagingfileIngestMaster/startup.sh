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

    source $scripts/shared/put.sh

    # Now verify if a file with the given length and md5 exists so we can remove it from the fs
    query="{md5:'$md5',length:$length}"
    mustHave=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').findOne($query).metadata.pid")
    if [ "$mustHave" == "$pid" ] ; then
        rm -f $l
	    rm -f $l.md5
	    exit 0
    else
        echo "Error. No file found with $query"
        echo "Expected  $pid"
        echo "Was       $mustHave"
        exit -1
    fi
fi

exit $?
