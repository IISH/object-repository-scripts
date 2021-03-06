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
statistics=$1
if [ -z "$statistics" ] ; then
    statistics=0
fi

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
    done
done

# Produce labels
for db in ${dbs[*]}
do
    mongo $db --eval "db.label.remove();"
    mongo $db --eval "db.master.files.find({'metadata.label':{\$exists:true}},{'metadata.label':1}).forEach( \
        function(d){db.label.update({_id:d.metadata.label},{\$inc:{size:1}}, true, false)})"
done


# See if we need to send a report.
report=/tmp/report.txt
mongo $DB_SHARD/shard --quiet --eval "var format='csv'; var from=-28;" $scripts/utils/candidate_history.js > $report
usable=$(mongo $DB_SHARD/shard --quiet --eval "var usable=0; db['candidate'].find().forEach(function(c){usable+=c.usable});usable")
if [[ $usable -lt $STORAGE_MINIMUM ]] ; then
    python $scripts/utils/sendmail.py --body "$report" --from "$OR_MAIL_FROM" --to "$OR_MAIL_TO" --subject "$OR_SUBJECT" --mail_relay "$OR_MAIL_RELAY" --mail_user "$OR_MAIL_USER" --mail_password "$OR_MAIL_PASSWORD"
fi


today=$(date +"%d")
if [[ $today == $statistics ]]; then
    # Calculate storage statistics
    for db in ${dbs[*]}
    do
        echo "Storage statistics for $db"
        mongo $db $scripts/shared/storage.js
    done
fi


# Create site usage
for db in ${dbs[*]}
do
    echo "Siteusage IP for $db"
    #source $scripts/shared/siteusage.sh $db
done

# Produce virtual file system
#for db in ${dbs[*]}
#do
#    mongo $db --eval "db.vfs.drop(); printjson(db.runCommand({getlasterror:1, w:'2'}))"
#    for c in master level1 level2 level3
#    do
#        mongo $db --eval "var ns='$c';" $scripts/shared/vfs.js
#    done
#    mongo $db --eval "db.vfs.ensureIndex({'f.p':1})"
#    mongo $db --eval "db.vfs.ensureIndex({'f.o':1})"
#done