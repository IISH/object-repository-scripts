#!/bin/bash
#
# list_archive_objid [ARCH number]
#
# Description
# Create an update script for archival objects.

scripts="$scripts"


db="$1"
if [ -z "$db" ]
then
    echo "db not set"
    exit 1
fi


objid="$2"
if [ -z "$objid" ]
then
    echo "objid prefix not set"
    exit 1
fi


tmp="/tmp/a.txt"
file="/tmp/b.txt"
mongo "$db" --quiet --eval "db.master.files.find({'metadata.objid':{\$regex:'^$objid\.'}}).forEach(function(d){print(d.metadata.objid)})" > "$tmp"
cat "$tmp" | sort -u > "$file"

echo "#!/bin/bash" > "$tmp"
while read objid
do
    for bucket in master level1 level2 level3
    do
        echo "${objid}.${bucket}"
        mongo "$db" --quiet --eval "var seq=0;db.$bucket.files.find({'metadata.objid':'$objid'}).sort({'metadata.seq':1}).forEach(function(d){print('mongo $db --quiet --eval \"db.$bucket.files.update({_id:' + d._id + '},{\\\\\$set:{\'metadata.seq\':' + ++seq + '}}, false, false)\"')})" >> "$tmp"
        rc=$?
        if [[ $rc != 0 ]]
        then
            echo "There was an error ${rc}"
            tail "$tmp"
            exit 1
        fi
    done
done < "$file"

chmod 744 "$tmp"
"./${tmp}"