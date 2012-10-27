#!/bin/bash
#
# StagingFileIngestMaster/startup.sh
#
# Insert a Master file into the database

scripts=$scripts
fileSet=$fileSet
bucket="master"
source $scripts/shared/parameters.sh
derivative=$derivative
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
    exit $?
fi

# If we find a file we upload it
mongo $db --quiet --eval "db.label.update( {'_id' : '$label'}, {\$inc:{size:1}}, true, false)"
if [ -f "$l" ] ; then
    remove="yes"

    if [ "$derivative" == "image" ] ; then
        content=$(identify -format "{height:'%h',width:'%w','x-resolution':'%x','y-resolution':'%y'}" "$l")
    fi
    if [ "$derivative" == "audio" ] ; then
        content=$(ffprobe -v quiet -print_format json -show_format -show_streams "$l")
    fi
    if [ "$derivative" == "video" ] ; then
        content=$(ffprobe -v quiet -print_format json -show_format -show_streams "$l")
    fi

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
