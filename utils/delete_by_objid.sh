#!/bin/bash
#
# delete_by_objid.sh
#
# Remove all files with the given objid


db="$1"
if [ -z "$db" ]
then
    echo "db not set"
    exit 1
fi


objid="$2"
if [ -z "$objid" ]
then
    echo "objid not set"
    exit 1
fi


buckets="master level1 level2 level3"


echo "db: ${db}"
echo "objid: ${objid}"
echo "buckets: ${buckets}"


query="{'metadata.objid':'${objid}'}"
found_one=$(mongo $db --eval "db.master.files.findOne(${query})")
if [ -z "$found_one" ]
then
    echo "No files found with ${query}"
    exit 2
fi


echo "The number of files that will be deleted are:"
for bucket in $buckets
do
    count=$(mongo $db --eval "db.${bucket}.files.count(${query})")
    echo "${db}.${bucket}: ${count}"
done


echo "WARNING! THIS WILL REMOVE ALL FILES WITH OBJID ${objid}"
echo -n "Do you want to proceed [NO|yes] ?"
read proceed
proceed="${proceed,,}"


if [ "$proceed" == "yes" ]
then
    tmp_dir="/tmp/pids.${objid}"
    mkdir -p "$tmp_dir"
    file="${tmp_dir}/pids.txt"
    mongo $db --eval "db.master.files.find(${query},{'metadata.pid':1}).forEach(function(){print(d.metadata.pid)})">$file
    for pid in pids
    do
        query="{'metadata.pid':'${pid}'}"
        for bucket in buckets
        do
            _id=$(mongo $db --eval "db.${bucket}.files.findOne({'${pid}'},{_id:1})")
            if [ -z "$_id" ]
            then
                echo "Error: no _id found for ${pid}"
                exit 3
            else
                echo "Deleting ${db}.${bucket}.${_id} from ${bucket}.files and ${bucket}.chunks"
                mongo $db --eval "db.${bucket}.files.remove({_id:${_id})"
                mongo $db --eval "db.${bucket}.chunks.remove({files_id:${_id})"
            fi
        done
    done < $file
else
    echo "Aborted because you types ${proceed}"
    exit 4
fi