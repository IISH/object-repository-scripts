#!/bin/bash


FILE_WITH_ERRORS="$1"
if [ ! -f "$FILE_WITH_ERRORS" ]
then
    echo "$FILE_WITH_ERRORS"
    exit 1
fi

while read line
do read replicaset_number id <<< "$line"
    report="${replicaset_number}.${id}.csv"
    "${scripts}/utils/chunk_checks.sh" "$replicaset_number" "or_10622" "master" "$id" > "$report"
done < "$FILE_WITH_ERRORS"