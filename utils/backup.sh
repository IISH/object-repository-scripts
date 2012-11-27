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

# Backup the config server's dat
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

# Calculate siteusage statistics
for db in ${dbs[*]}
do
        echo "Siteusage for $db"
        source $scripts/shared/siteusage.sh
done

# Calculate storage statistics
for db in ${dbs[*]}
do
        echo "Storage statistics for $db"
        mongo $db --eval "var pid=null" $scripts/shared/statistics.js
done

# Produce labels
for db in ${dbs[*]}
do
    mongo $db --eval "db.label.remove();"
    mongo $db --eval "db.master.files.find({},{'metadata.label':1}).forEach( \
        function(d){db.label.update({_id:d.metadata.label},{\$inc:{size:1}}, true, false)})"
done

