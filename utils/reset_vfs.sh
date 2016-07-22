#!/bin/bash
#
# reset_vfs.sh [database]
#
# Description
# Empty the vsf collection and restore all file references.


db="$1"
if [ -z "$db" ]
then
    echo "Need a database"
    exit 1
else
    echo "clear the vfs"
    mongo "$db" --eval "db.vfs.drop()"
fi


for bucket in master
do
    file_pids="/tmp/${db}.${bucket}.pids.txt"
    echo "Create a list of PID values: ${file_pids}"
    mongo "$db" --quiet --eval "db.${bucket}.files.find({},{_id:0, 'metadata.pid':1}).forEach(function(d){print(d.metadata.pid)})" > "$file_pids"
    # Now, for each PID set the vfs
    while read pid
    do
        echo "Set vfs document for ${pid}"
        mongo "$db" --quiet --eval "var pid='$pid';var ns='$bucket'" "$scripts/shared/vfs.js"
    done < "$file_pids"
done


mongo "$db" --eval "db.vfs.createIndex({'f.o':1})"
mongo "$db" --eval "db.vfs.createIndex({'f.p':1})"