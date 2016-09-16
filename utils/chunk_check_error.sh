#!/bin/bash


FILE_WITH_ERRORS="$1"
rm "$FILE_WITH_ERRORS"

while read line
do read replicaset_number id <<< "$line"
    report="${replicaset_number}.${id}.csv"
    "${scripts}/utils/chunk_checks.sh" "$replicaset_number" "or_10622" "master" "$id" > "$report"
done < "$FILE_WITH_ERRORS"