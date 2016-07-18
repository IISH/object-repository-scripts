#!/bin/bash

host=$1
db=$2
ns=$3
_id=$4
file="${host}.${db}.${ns}.${_id}"

echo "host=${host}"
echo "db=${db}"
echo "ns=${ns}"
echo "_id=${_id}"

echo "Retrieving chunks to ${file}"
mongo $db --quiet --eval "var ns='$ns'; var _id='$_id'; var host='$host';" $scripts/utils/chunk_check.js > $file

echo "Calculating md5 per chunk to ${file}.check"
python $scripts/utils/chunk_check.py -f $file > $file.check
