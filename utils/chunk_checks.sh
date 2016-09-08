#!/bin/bash


scripts="$scripts"
replicaset=$1
db=$2
bucket=$3
_id=$4
target="or-mongodb-${replicaset}.${db}.${bucket}.${_id}"
echo "HOST N EXPECTED ACTUAL MATCH" >  "$target"


for replica in 02 00 01
do
    echo "Retrieve the chunks"
    host="or-mongodb-${replicaset}-${replica}:27018"
    file="${host}.${db}.${bucket}.${_id}"
    "${scripts}/utils/chunk_check.sh" "$host" "$db" "$bucket" "$_id" > "$file"

    f="${file}.check"
    echo "Calculating md5 per chunk to ${f}"
    python "${scripts}/utils/chunk_check.py" -f "$file" > "$f"
    paste "$target" "$f" | column -s ',' -t >> "$target"
done