#!/bin/bash
#
# chunk_check.sh [host] [database] [bucket] [id]


scripts="$scripts"
host=$1
db=$2
bucket=$3
_id=$4
file="${host}.${db}.${bucket}.${_id}"

echo "host=${host}"
echo "db=${db}"
echo "bucket=${bucket}"
echo "_id=${_id}"

echo "Retrieving chunks to ${file}"
mongo "$db" --quiet --eval "var bucket='${bucket}'; var _id='${_id}'; var host='${host}';" "${scripts}/utils/chunk_check.js"
