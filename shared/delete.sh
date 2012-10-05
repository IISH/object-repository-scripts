#!/bin/bash
#
# Reads a file from the database.collection and removes it.
#
db=$db
pid=$pid

for bucket in "master" "level1" "level2" "level3"
do
    files_id=$(mongo $db --quiet --eval "var doc=db.$bucket.files.findOne({'metadata.pid':'$pid'}, {_id:1});if ( doc ){print(doc._id)}")
    if [ -z $files_id ] ; then
        echo "PID $pid not in database."
        exit -1
    fi

    mongo $db --quiet --eval "db.$bucket.files.remove({_id:'$files_id'})"
    mongo $db --quiet --eval "db.$bucket.chunks.remove({files_id:'$files_id'})"

    # Verify our removal
    count=$(mongo $db --quiet --eval "db.$bucket.files.count({_id:'$files_id'})")
    if [ $count != 0 ] ; then
        echo "Failed to delete document $pid in files.$bucket"
        exit -1
    fi

    count=$(mongo $db --quiet --eval "db.$bucket.chunks.count({files_id:'$files_id'})")
    if [ $count != 0 ] ; then
        echo "Failed to delete document $pid in chunks.$bucket"
        exit -1
    fi
done

echo "Document $pid removed"

exit $?