#!/bin/bash


scripts="$scripts"
replicaset=$1
db=$2
bucket=$3
_id=$4
target="or-mongodb-${replicaset}.${db}.${bucket}.${_id}"
rm "$target"


for replica in 2 0 1
do
    echo "Retrieve the chunks"
    host="or-mongodb-${replicaset}-2.objectrepository.org:27018"
    file="${host}.${db}.${bucket}.${_id}"
    "${scripts}/utils/chunk_check.sh" "$host" "$db" "$bucket" "$_id" > "$file"

    f="${file}.check"
    echo "Calculating md5 per chunk to ${f}"
    python "${scripts}/utils/chunk_check.py" -f "$file" > "$f"
    paste "$target" "$f" | column -s ',' -t >> "$target"
done

