#!/bin/bash
#
# delete_by_pid.sh [db] [pid]
#
# Remove the master and derivative file


scripts="$scripts"


db="$1"
if [ -z "$db" ]
then
    echo "db not set"
    exit 1
fi


pid="$2"
if [ -z "$pid" ]
then
    echo "pid not set"
    exit 1
fi


for bucket in master level1 level2 level3
do
    files_id=$(mongo "$db" --quiet --eval "var doc=db.${bucket}.files.findOne({'metadata.pid':'${pid}'}, {_id:1});if ( doc ){print(doc._id)}")
    if [ -z "$files_id" ]
    then
        echo "No such file with ${pid}"
        exit 1
    else
        echo "Remove ${pid} with _id ${files_id}"
        mongo "$db" --quiet --eval "db.$bucket.files.remove({_id:$files_id})"
        mongo "$db" --quiet --eval "db.$bucket.chunks.remove({files_id:$files_id})"
        mongo "$db" --quiet --eval "var pid='${pid}';var ns='$bucket'; var del=true;" "$scripts/shared/vfs.js"
    fi
done