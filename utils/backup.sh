#!/bin/bash
#
# /shared/backup.sh
#
# Backup for the metadata
#
#
# ToDo: retrieve the database names from the database itself
cd /data/backup
scripts=$scripts
dbs=$dbs

# Backup the config server database
mongodump -d config

#backup the fsGrid metadata
for db in ${dbs[*]}
do
    for c in level3.files level2.files level1.files master.files
    do
        echo "Mongodump on $db.$c"
        mongodump -d $db -c $c
    done
done

# Siteusage statistics
for db in ${dbs[*]}
do
    echo "Siteusage IP for $db"
    source $scripts/shared/siteusage.sh
    rc=$?
    if [[ $rc != 0 ]] ; then
        echo "The siteusage.sh procedure did not return a clean exit code."
        exit $rc
    fi
done

# Produce labels
for db in ${dbs[*]}
do
    mongo $db --eval "db.label.remove();"
    mongo $db --eval "db.master.files.find({'metadata.label':{\$exists:true}},{'metadata.label':1}).forEach( \
        function(d){db.label.update({_id:d.metadata.label},{\$inc:{size:1}}, true, false)})"
done

#For speed store the information into a temporary database where we will do our mapreduce tasks
rm /data/db/*
mongorestore --dbpath=/data/db

# Siteusage statistics
service mongodb start
for db in ${dbs[*]}
do
    echo "Siteusage mapreduce for $db"
    mongo localhost:27018/$db --eval "var pid=null" $scripts/shared/siteusage.js
done

# Calculate storage statistics
for db in ${dbs[*]}
do
    echo "Storage statistics for $db"
    mongo localhost:27018/$db --eval "var pid=null" $scripts/shared/statistics.js
done

service mongodb stop

# As we are done we can dump the collections back into the backup
for db in ${dbs[*]}
do
    for unit in year month week day
    do
        mongodump --dbpath=/data/db --directoryperdb /data/backup/dump/$db -c $unit.siteusage.statistics
        mongodump --dbpath=/data/db --directoryperdb /data/backup/dump/$db -c $unit.storage.statistics
        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "Failed to dump collection"
            exit -1
        fi
    done
done

for db in ${dbs[*]}
do
    dbpath=/data/backup/dump/$db
    for unit in year month week day
    do
        mongodump -d $db -c $unit.siteusage.statistics --drop
        mongodump -d $db -c $unit.storage.statistics --drop
        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "Failed to dump collection"
            exit -1
        fi
    done
done


