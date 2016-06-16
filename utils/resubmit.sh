#!/bin/bash
#
# resubmit.sh [objid]
#
# example: resubmit.sh 10622/BULK12345

objid="$1"
if [ -z "$objid" ]
then
    echo "objid not set"
    exit 1
fi


na=${objid:0:5}
id=${objid:6}
if [ ! "$objid" == "${na}/${id}" ]
then
    echo "The expected na and id are not correctly derived from the objid."
    echo "Eg: ./resubmit.sh 10622/BULK12345"
    exit 2
fi

$scripts/utils/delete_by_objid.sh "$objid"

fileset="/mnt/sa/10622/23445/${id}"
backup="/mnt/sa/10622/23445/.${id}"
# remove the old instruction
query="{fileSet:'${fileset}'}"
mongo sa --quiet --eval "db.instruction.remove($query)"
mongo sa --quiet --eval "db.stagingfile.remove($query)"

mv "$fileset" "$backup"