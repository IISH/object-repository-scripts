#!/bin/bash
#
# delete_by_objid.sh
#
# Remove all files with the given objid


objid="$1"
if [ -z "$objid" ]
then
    echo "objid not set"
    exit 1
fi



buckets="master level1 level2 level3"
na=${objid:0:5}
id=${objid:6}
db="or_${na}"
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
    for bucket in $buckets
    do
        tmp_dir="/tmp/pids.${objid}"
        mkdir -p "$tmp_dir"
        file="${tmp_dir}/pids.txt"
        mongo $db --quiet --eval "db.${bucket}.files.find(${query},{'_id':1}).forEach(function(d){print(d._id)})">$file
        while read _id
        do
            echo "Deleting ${db}.${bucket}.${_id} from ${bucket}.files and ${bucket}.chunks"
            # Remove from the datastore
            mongo ${db} --quiet --eval "db.${bucket}.files.remove({_id:${_id}})"
            mongo ${db} --quiet --eval "db.${bucket}.chunks.remove({files_id:${_id}})"
            # Remove from the vfs
            mongo --quiet --eval "db.vfs.remove({'_id': { \$regex: /${na}\/${bucket}\/${id}/}})"
        done < $file
    done
else
    echo "Aborted because you typed ${proceed}"
    exit 4
fi