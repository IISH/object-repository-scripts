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

# Backup the config server's dat
mongodump -d config

#backup the fsGrid metadata
for d in or_10622 or_10798 or_10848 or_10851 or_10891
do
        for c in level3.files level2.files level1.files master.files
        do
                echo "Mongodump on $d.$c"
                mongodump -d $d -c $c
        done
done

# Calculate siteusage statistics
for d in 10622 10798 10848 10851 10891
do
        echo "Siteusage for $d"
        source $scripts/shared/siteusage.sh -na $d
done

# Calculate storage statistics
for d in 10622 10798 10848 10851 10891
do
        echo "Storage statistics for $d"
        mongo $d --eval "var pid=null" $scripts/shared/statistics.js
done

# Produce labels
for d in 10622 10798 10848 10851 10891
do
    mongo $d --eval "db.label.remove();"
    mongo $d --eval "db.master.files.find({},{'metadata.label':1}).forEach( \
        function(d){db.label.update({_id:d.metadata.label},{\$inc:{size:1}}, true, false)})"
done

