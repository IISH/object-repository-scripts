#!/bin/bash
#
# chunk_checks.sh [replica set number] [database] [bucket] [id]
#
# Description
# Produce a list for this file that contains a true or false statement if an identified damaged chunk can be recovered.


scripts="$scripts"
REPLICASET=$1
DB=$2
BUCKET=$3
_ID=$4


function export {
    chunk 0 "secondary.csv"
    chunk 1 "delay.csv"
    chunk 2 "primary.csv"
}


function chunk {
    r="$1"
    file="$2"
    echo "Retrieve the chunks"
    host="or-mongodb-${REPLICASET}-${r}.objectrepository.org:27018"
    tmp="file.csv"
    "${scripts}/utils/chunk_check.sh" "$host" "$DB" "$BUCKET" "$_ID" > "$tmp"
    python "${scripts}/utils/chunk_check.py" -f "$tmp" > "$file"
    rm "$tmp"
}


function recover {
    "${scripts}/utils/chunk_recover.py" --primary primary.csv --secondary secondary.csv --delay delay.csv
}


function main {
    export
    recover
}


main