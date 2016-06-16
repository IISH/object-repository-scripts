#!/bin/bash
#

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
    exit 2
fi

$scripts/utils/delete_by_objid.sh "$na" "$objid"

d="/mnt/sa/10622/23445/$1"
if [ -d "$d" ] ; then
    find "$d" -type f -exec $scripts/utils/md5.remove.file.sh {} \;
fi