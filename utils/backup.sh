#!/bin/bash
#
# /shared/backup.sh
#
# Backup for the metadata
#
#
cd /data/backup
scripts=$scripts
# ToDo: retrieve the database names from the database itself
dbs=$dbs

# Backup the config server database
mongodump -d config

# Backup the stagingarea and user base
mongodump -d sa
mongodump -d security

#backup the fsGrid metadata
for db in ${dbs[*]}
do
    for c in level3.files level2.files level1.files master.files
    do
        echo "Mongodump on $db.$c"
        mongodump -d $db -c $c
        mongodump -d $db -c siteusage
    done
done

# Produce labels
for db in ${dbs[*]}
do
    mongo $db --eval "db.label.remove();"
    mongo $db --eval "db.master.files.find({'metadata.label':{\$exists:true}},{'metadata.label':1}).forEach( \
        function(d){db.label.update({_id:d.metadata.label},{\$inc:{size:1}}, true, false)})"
done

# Calculate storage statistics
for db in ${dbs[*]}
do
    echo "Storage statistics for $db"
    mongo $db $scripts/shared/storage.js
done

# Create site usage
for db in ${dbs[*]}
do
    echo "Siteusage IP for $db"
    #source $scripts/shared/siteusage.sh $db
done

# Produce virtual file system
#for db in ${dbs[*]}
#do
#    mongo $db --eval "db.vfs.drop(); printjson(db.runCommand({getlasterror:1, w:'majority'}))"
#    for c in master level1 level2 level3
#    do
#        mongo $db --eval "var ns='$c';" $scripts/shared/vfs.js
#    done
#    mongo $db --eval "db.vfs.ensureIndex({'f.p':1})"
#    mongo $db --eval "db.vfs.ensureIndex({'f.o':1})"
#done