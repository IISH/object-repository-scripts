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
    # clear the vfs
    mongo "$db" --eval "db.vfs.drop()"
    sleep 10
    mongo "$db" --eval "db.vfs.createIndex({'f.o':1})"
    mongo "$db" --eval "db.vfs.createIndex({'f.p':1})"
fi


for bucket in master
do
    # Create a list of PID values
    file_pids = "/tmp/${db}.${bucket}.pids.txt"
    mongo "$db" --quiet --eval "db.${bucket}.files.find({},{_id:0, 'metadata.pid':1})" > "$file_pids"

    # Now, for each PID set the vfs
    for read pid
    do
        mongo "$db" --quiet --eval "var pid='$pid';var ns='$bucket'" $(cwp "$scripts/shared/vfs.js")
    done < "$file_pids"
done
