#!/bin/bash

host=$1
db=$2
ns=$3
_id=$4

echo "host=${host}"
echo "db=${db}"
echo "ns=${ns}"
echo "_id=${_id}"

file="${host}.${db}.${ns}.${_id}"
mongo $db --quiet --eval "var ns='$ns'; var _id='$_id'; var host='$host';" $scripts/utils/chunk_check.js > $file
python $scripts/chunk_check.py -f $file > $file.check
