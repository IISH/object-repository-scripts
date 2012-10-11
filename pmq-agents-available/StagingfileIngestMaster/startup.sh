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
action=$action

source $scripts/shared/primary.sh

if [ "$action" == "delete" ] ; then
    for b in "master" "level1" "level2" "level3"
    do
        bucket=$b
        source $scripts/shared/delete.sh
    done
fi

# If we find a file we upload it
mongo $db --quiet --eval "db.label.update( {'_id' : '$label'}, {\$inc:{size:1}}, true, false)"
if [ -f "$l" ] ; then
    remove="yes"
    source $scripts/shared/put.sh
else
    echo "No location '$l' found... updating metadata for the $db.$bucket collection"
    query="{'metadata.pid':'$pid'}"
    update="{'metadata.access':'$access',contentType:'$contentType','metadata.label':'$label'}"
    mongo $db --quiet --eval "db.getCollection('$bucket.files').update($query,{\$set:$update}, false, false);''"
    rc=$?
    if [[ $rc != 0 ]] ; then
        exit $rc
    fi

    # Verify
    query="{\$and:[$query,$update]}"
    countOne=$(mongo $db --quiet --eval "db.getCollection('$bucket.files').find($query).count()")
    if [ $countOne == 1 ] ; then
	    echo "File metadata updated."
	    exit 0
    fi
    echo "The expected updated elements cannot be found with the query $query"
    exit -1
fi



exit $?
