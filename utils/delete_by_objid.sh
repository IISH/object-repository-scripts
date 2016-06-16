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


buckets="master"
na=${objid:0:5}
id=${objid:6}
echo "db: ${db}"
echo "objid: ${objid}"
echo "na: ${na}"
echo "id: ${id}"
echo "buckets: ${buckets}"


if [ ! "$objid" == "${na}/${id}" ]
then
    echo "The expected na and id are not correctly derived from the objid."
    exit 2
fi


query="{'metadata.objid':'${objid}'}"
found_one=$(mongo $db --quiet --eval "db.master.files.findOne(${query})")
if [ "$found_one" == "null" ]
then
    echo "No files found with ${query}"
    exit 3
fi


echo "The number of files that will be deleted are:"
for bucket in $buckets
do
    count=$(mongo $db --quiet --eval "db.${bucket}.files.count(${query})")
    echo "db.${bucket}.files.count(${query})=${count}"
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
    mongo $db --quiet --eval "db.master.files.find(${query},{'metadata.pid':1}).forEach(function(d){print(d.metadata.pid)})">$file
    while read pid
    do
        query="{'metadata.pid':'${pid}'}"
        for bucket in $buckets
        do
            _id=$(mongo $db --quiet --eval "var doc=db.${bucket}.files.findOne(${query},{_id:1}); if (doc) print(doc._id); else print('null');")
            echo "Deleting ${db}.${bucket}.${_id} from ${bucket}.files and ${bucket}.chunks"
            if [ "$_id" == "null" ]
            then
                echo "Warning: no _id found for ${query}"
            else
                # Remove from the datastore
                mongo ${db} --quiet --eval "db.${bucket}.files.remove({_id:${_id}})"
                mongo ${db} --quiet --eval "db.${bucket}.chunks.remove({files_id:${_id}})"
                # Remove from the vfs
                mongo --quiet --eval "db.vfs.remove({'_id': { \$regex: /${na}\/${bucket}\/${id}/}})"
            fi
        done
    done < $file
else
    echo "Aborted because you typed ${proceed}"
    exit 4
fi