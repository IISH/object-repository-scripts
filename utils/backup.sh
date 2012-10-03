#!/bin/bash
#
# /shared/backup.sh
#
# Backup for the metadata
#
cd /data/backup
cd $1

for d in or_10622 or_10798 or_10848 or_10851 or_10891
do
        for c in level3.files level2.files level1.files master.files
        do
                echo "Mongodump on $d.$c"
                mongodump -d $d -c $c
        done
done
